#!/usr/bin/env python3
"""Niri coordinates + ydotool clicks. Points are percentages of one output."""
import argparse
import contextlib
import fcntl
import json
import math
import os
from pathlib import Path
import selectors
import signal
import subprocess
import sys
import time


def niri(command):
    return json.loads(subprocess.check_output(["niri", "msg", "-j", command], text=True))


def outputs():
    return {k: v for k, v in niri("outputs").items() if v.get("logical") is not None}


def coordinates(name, x, y, screens):
    logical = screens[name]["logical"]
    lx, ly = x, y
    return {
        "output": name, "x": logical["x"] + lx, "y": logical["y"] + ly,
        "local_x": lx, "local_y": ly,
        "percent_x": 100 * lx / max(1, logical["width"] - 1),
        "percent_y": 100 * ly / max(1, logical["height"] - 1),
    }


class Cursor:
    def __init__(self):
        self.screens = outputs()
        self.process = subprocess.Popen(["snowflake-cursor-reader"], stdout=subprocess.PIPE)
        self.selector = selectors.DefaultSelector()
        self.selector.register(self.process.stdout, selectors.EVENT_READ)
        self.buffer = b""
        self.current = None

    def update(self, timeout=0):
        if self.selector.select(timeout):
            chunk = os.read(self.process.stdout.fileno(), 65536)
            if not chunk:
                raise RuntimeError("O leitor do cursor encerrou. Confira o erro acima.")
            self.buffer += chunk
            while b"\n" in self.buffer:
                line, self.buffer = self.buffer.split(b"\n", 1)
                name, x, y = line.decode().split("\t")
                if name in self.screens:
                    point = coordinates(name, float(x), float(y), self.screens)
                    logical = self.screens[name]["logical"]
                    # Capture sessions may also report an image overlapping an output edge.
                    if 0 <= point["local_x"] < logical["width"] and 0 <= point["local_y"] < logical["height"]:
                        self.current = point
        return self.current

    def initial(self):
        deadline = time.monotonic() + 5
        while self.current is None and time.monotonic() < deadline:
            self.update(0.1)
        if self.current is None:
            raise RuntimeError("Sem posição do cursor. Mova o mouse e execute novamente.")
        return self.current

    def close(self):
        self.selector.close()
        self.process.terminate()
        try:
            self.process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait()
            raise RuntimeError("A camada de medição não encerrou normalmente. O clique foi cancelado.") from None
        self.process.stdout.close()
        if self.process.returncode != 0:
            raise RuntimeError("O leitor encerrou com erro. O clique foi cancelado.")

    def move(self, name, x, y):
        self.initial()
        for attempt in range(8):
            # Drain pending samples so displacement is based on the latest event.
            while self.selector.select(0):
                self.update()
            p = self.current
            dx, dy = round(x - p["x"]), round(y - p["y"])
            if p["output"] == name and abs(dx) <= 1 and abs(dy) <= 1:
                return
            subprocess.run(["ydotool", "mousemove", "--", str(dx), str(dy)], check=True)
            deadline = time.monotonic() + 0.2
            while time.monotonic() < deadline:
                self.update(min(0.02, max(0, deadline - time.monotonic())))
        raise RuntimeError("Cursor não chegou ao ponto; nenhum clique nesse ponto foi enviado. Não mova o mouse durante o macro.")


def number(value, label, low, high):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or not low <= value <= high:
        raise ValueError(f"{label} deve ser um número entre {low} e {high}.")
    return value


def plan(config, screens, chosen_output, profile):
    override = config.get("hosts", {}).get(profile, {})
    merged = {**config, **override}
    name = chosen_output or merged.get("output", "auto")
    if name == "auto":
        name = next((w["output"] for w in niri("workspaces") if w["is_focused"]), None)
    if name not in screens:
        raise ValueError(f"Monitor {name!r} indisponível. Disponíveis: {', '.join(screens)}")
    raw = merged.get("points", [])
    if not raw:
        raise ValueError("Defina points em ~/.config/snowflake/macro.json. Use cursor-pos para obter x e y em porcentagem.")
    points = []
    logical = screens[name]["logical"]
    for p in raw:
        x = number(p["x"], "x (%)", 0, 100)
        y = number(p["y"], "y (%)", 0, 100)
        delay = number(p.get("delay", 0.3), "delay (segundos)", 0, 3600)
        button = p.get("button", "left")
        if button not in ("left", "right", "middle"):
            raise ValueError("button deve ser left, right ou middle.")
        points.append((logical["x"] + x / 100 * (logical["width"] - 1),
                       logical["y"] + y / 100 * (logical["height"] - 1), button, delay))
    return name, points, number(merged.get("startDelay", 2), "startDelay", 0, 3600)


def lock_path():
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not runtime:
        raise RuntimeError("XDG_RUNTIME_DIR não definido. Execute na sua sessão gráfica.")
    return Path(runtime) / "snowflake-macro.lock"


@contextlib.contextmanager
def measurement_lock():
    with lock_path().with_name("snowflake-cursor.lock").open("a+") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError("Já existe um cursor-pos ou macro ativo. Encerre-o antes de continuar.") from None
        yield


def stop():
    with lock_path().open("a+") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            print("Nenhum macro em execução.")
            return
        except BlockingIOError:
            lock.seek(0)
            pid = int(lock.read().strip())
            cmdline = Path(f"/proc/{pid}/cmdline").read_bytes().split(b"\0")
            if not any(arg.endswith(b"/macro.py") for arg in cmdline) or b"macro" not in cmdline:
                raise RuntimeError("Não foi possível confirmar o processo do macro.")
            os.kill(pid, signal.SIGTERM)
            print("Macro interrompido.")


def run_macro(args):
    if args.stop:
        return stop()
    config = json.loads(args.config.read_text())
    screens = outputs()
    name, points, delay = plan(config, screens, args.output, os.environ.get("SNOWFLAKE_PROFILE", ""))
    if args.dry_run:
        print(f"Monitor: {name} | espera inicial: {delay}s")
        for x, y, button, pause in points:
            print(f"x={round(x)} y={round(y)} | {button} | pausa={pause}s")
        return
    with lock_path().open("a+") as lock, measurement_lock():
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError("Já existe um macro em execução. Use macro --stop.") from None
        lock.seek(0)
        lock.truncate()
        lock.write(str(os.getpid()))
        lock.flush()
        print(f"Macro em {name}, começando em {delay}s. Ctrl+C ou macro --stop para parar.", flush=True)
        time.sleep(delay)
        # Abort before any click if monitor geometry changed during the countdown.
        if outputs() != screens:
            raise RuntimeError("Os monitores mudaram durante a espera. Execute novamente.")
        for x, y, button, pause in points:
            if outputs() != screens:
                raise RuntimeError("Os monitores mudaram durante o macro. Execute novamente.")
            with contextlib.closing(Cursor()) as cursor:
                cursor.move(name, x, y)
            # close() waits until the transparent layer is removed by the compositor.
            subprocess.run(["ydotool", "click", {"left": "0xC0", "right": "0xC1", "middle": "0xC2"}[button]], check=True)
            time.sleep(pause)
        print("Macro concluído.")


def watch(args):
    with measurement_lock(), contextlib.closing(Cursor()) as cursor:
        cursor.initial()
        refreshed = time.monotonic()
        if not args.json:
            print("Posição global e relativa ao monitor. Modo medição: o mouse fica na camada transparente. Ctrl+C para sair.")
        while True:
            if time.monotonic() - refreshed > 1:
                cursor.screens = outputs()
                refreshed = time.monotonic()
            p = cursor.update(0.05)
            if args.json:
                print(json.dumps(p), flush=True)
            else:
                print(f"\r\033[2K{p['output']} | global: {p['x']:.0f}, {p['y']:.0f} | "
                      f"local: {p['local_x']:.0f}, {p['local_y']:.0f} | "
                      f"macro: x={p['percent_x']:.3f}, y={p['percent_y']:.3f}", end="", flush=True)


def main():
    command = sys.argv[1]
    parser = argparse.ArgumentParser(prog=command)
    if command == "macro":
        default = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "snowflake/macro.json"
        parser.add_argument("--config", type=Path, default=default)
        parser.add_argument("--output", help="Nome do monitor; padrão: monitor da workspace focada")
        parser.add_argument("--dry-run", action="store_true", help="Mostra os pontos sem mover/clicar")
        parser.add_argument("--stop", action="store_true", help="Interrompe o macro em execução")
    else:
        parser.add_argument("--json", action="store_true", help="Retorna uma linha JSON a cada atualização")
    args = parser.parse_args(sys.argv[2:])
    signal.signal(signal.SIGTERM, lambda *_: (_ for _ in ()).throw(KeyboardInterrupt()))
    try:
        (run_macro if command == "macro" else watch)(args)
    except KeyboardInterrupt:
        print("\nInterrompido.")
    except (OSError, ValueError, KeyError, TypeError, RuntimeError, subprocess.SubprocessError) as e:
        print(f"Erro: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
