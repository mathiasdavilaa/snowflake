const float TRAIL_DURATION = 0.24;
const float TRAIL_OPACITY = 0.65;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 screen = texture(iChannel0, uv);
    fragColor = screen;

    float age = max(iTime - iTimeCursorChange, 0.0);
    if (age >= TRAIL_DURATION || iCursorVisible.x < 0.5
        || min(iPreviousCursor.z, iPreviousCursor.w) <= 0.0) {
        return;
    }

    vec2 currentSize = max(iCurrentCursor.zw, vec2(1.0));
    vec2 previousSize = max(iPreviousCursor.zw, vec2(1.0));
    vec2 current = iCurrentCursor.xy + vec2(currentSize.x, -currentSize.y) * 0.5;
    vec2 previous = iPreviousCursor.xy + vec2(previousSize.x, -previousSize.y) * 0.5;
    vec2 jump = current - previous;
    float jumpLength = length(jump);

    if (jumpLength < max(currentSize.x * 1.5, 3.0)) {
        return;
    }

    float progress = clamp(age / TRAIL_DURATION, 0.0, 1.0);
    float ease = 1.0 - pow(1.0 - progress, 3.0);
    vec2 tail = mix(previous, current, ease);
    vec2 travel = current - tail;
    float travelLength = length(travel);
    if (travelLength < 0.75) {
        return;
    }

    vec2 cursorMin = iCurrentCursor.xy + vec2(0.0, -currentSize.y);
    vec2 cursorMax = iCurrentCursor.xy + vec2(currentSize.x, 0.0);
    if (all(greaterThanEqual(fragCoord, cursorMin))
        && all(lessThanEqual(fragCoord, cursorMax))) {
        return;
    }

    vec2 direction = travel / travelLength;
    vec2 normal = vec2(-direction.y, direction.x);
    float along = clamp(dot(fragCoord - tail, direction) / travelLength, 0.0, 1.0);
    vec2 nearest = tail + direction * (along * travelLength);

    float halfWidth = max(dot(abs(normal), currentSize * 0.5), 1.0);
    float width = halfWidth * mix(0.12, 1.0, along);
    float distanceToTrail = length(fragCoord - nearest);
    float coverage = 1.0 - smoothstep(max(width - 0.75, 0.0), width + 0.75, distanceToTrail);
    float fade = (1.0 - progress) * (1.0 - progress);
    float alpha = coverage * fade * TRAIL_OPACITY * mix(0.2, 1.0, along);

    fragColor.rgb = mix(screen.rgb, iCurrentCursorColor.rgb, alpha);
    fragColor.a = screen.a;
}
