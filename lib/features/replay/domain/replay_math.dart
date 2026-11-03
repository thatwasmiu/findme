import 'dart:math';

// The same pace per print on every day, so a long day doesn't rush by.
const _msPerPrint = 120; // at 1×: 100 prints = 12 s, 1,000 prints = 2 min
const _minMs = 10000; // short days still last long enough to watch

int replayMs(int prints) => max(_minMs, (prints - 1) * _msPerPrint);

/// One step of the replay clock: `pos` moves through 0…n so the whole span takes [totalMs] at 1×; never past the end.
double advance(double pos, double dtMs, double speed, double totalMs, int n) =>
    min(n.toDouble(), pos + (dtMs * speed / totalMs) * n);

const speeds = <double>[0.5, 1, 2, 4, 8];

double nextSpeed(double s) => speeds[(speeds.indexOf(s) + 1) % speeds.length];
