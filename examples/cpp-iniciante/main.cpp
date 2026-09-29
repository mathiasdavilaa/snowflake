#include <iostream>

int main() {
    int numero = 0;
    std::cout << "Digite um numero: ";
    if (!(std::cin >> numero)) {
        std::cerr << "Entrada invalida. Digite um numero inteiro.\n";
        return 1;
    }
    const long long dobro = 2LL * numero;
    std::cout << "O dobro e " << dobro << '\n';
    return 0;
}
