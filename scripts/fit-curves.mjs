/**
 * Fits bezier curves to the Tailwind v4 oklch palette data.
 *
 * For each colour, we compute normalised curve y values at each tone:
 *   curveY = (tailwindL / anchor500L) * ANCHOR_Y
 *
 * Then fit a two-segment cubic bezier (the BezierCurve type) to those points
 * using gradient descent to minimise the sum of squared errors.
 *
 * Outputs a JS object suitable for pasting into colours.ts.
 */

const ANCHOR_Y = 0.5;
const TONES = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950];
const ANCHOR_X = 0.5;

function toneToX(tone) {
  return (tone - 50) / 900;
}

// Evaluate cubic bezier at t
function cubic(p0, cp0, cp1, p1, t) {
  const mt = 1 - t;
  return mt ** 3 * p0 + 3 * mt * mt * t * cp0 + 3 * mt * t * t * cp1 + t ** 3 * p1;
}
function cubicX(p0x, cp0x, cp1x, p1x, t) {
  return cubic(p0x, cp0x, cp1x, p1x, t);
}

// Binary search for t given x
function findT(p0x, cp0x, cp1x, p1x, targetX) {
  let lo = 0,
    hi = 1;
  for (let i = 0; i < 40; i++) {
    const mid = (lo + hi) / 2;
    const bx = cubicX(p0x, cp0x, cp1x, p1x, mid);
    if (Math.abs(bx - targetX) < 1e-8) return mid;
    if (bx < targetX) lo = mid;
    else hi = mid;
  }
  return (lo + hi) / 2;
}

function evaluateCurve(curve, x) {
  if (x <= 0) return curve.p0y;
  if (x >= 1) return curve.p1y;
  if (Math.abs(x - ANCHOR_X) < 1e-9) return ANCHOR_Y;
  if (x < ANCHOR_X) {
    const t = findT(0, curve.cp0x, curve.cpa0x, ANCHOR_X, x);
    return cubic(curve.p0y, curve.cp0y, curve.cpa0y, ANCHOR_Y, t);
  } else {
    const t = findT(ANCHOR_X, curve.cpa1x, curve.cp1x, 1, x);
    return cubic(ANCHOR_Y, curve.cpa1y, curve.cp1y, curve.p1y, t);
  }
}

// Compute sum of squared errors for a curve against target points
function sse(curve, targets) {
  let err = 0;
  for (const { x, y } of targets) {
    const predicted = evaluateCurve(curve, x);
    err += (predicted - y) ** 2;
  }
  return err;
}

// Simple gradient descent fitter
function fitCurve(targets, initial) {
  let curve = { ...initial };
  let lr = 0.1;
  const params = ["p0y", "cp0x", "cp0y", "cpa0x", "cpa0y", "cpa1x", "cpa1y", "cp1x", "cp1y", "p1y"];

  for (let iter = 0; iter < 5000; iter++) {
    if (iter % 500 === 499) lr *= 0.5;
    for (const param of params) {
      const delta = 1e-5;
      const orig = curve[param];
      const e0 = sse(curve, targets);
      curve[param] = orig + delta;
      const ep = sse(curve, targets);
      const grad = (ep - e0) / delta;
      curve[param] = orig - lr * grad;
      // Enforce constraints
      curve.cp0x = Math.min(ANCHOR_X, Math.max(0, curve.cp0x));
      curve.cpa0x = Math.min(ANCHOR_X, Math.max(0, curve.cpa0x));
      curve.cpa1x = Math.max(ANCHOR_X, Math.min(1, curve.cpa1x));
      curve.cp1x = Math.max(ANCHOR_X, Math.min(1, curve.cp1x));
      curve.p0y = Math.max(0, curve.p0y);
      curve.p1y = Math.max(0, Math.min(1, curve.p1y));
    }
  }
  return curve;
}

// Tailwind v4 oklch values: [L, C] per tone [50,100,200,300,400,500,600,700,800,900,950]
const TAILWIND = {
  red: {
    l: [0.971, 0.936, 0.885, 0.808, 0.704, 0.637, 0.577, 0.505, 0.444, 0.396, 0.258],
    c: [0.013, 0.032, 0.062, 0.114, 0.191, 0.237, 0.245, 0.213, 0.177, 0.141, 0.092],
  },
  orange: {
    l: [0.98, 0.954, 0.901, 0.837, 0.75, 0.705, 0.646, 0.553, 0.47, 0.408, 0.266],
    c: [0.016, 0.038, 0.076, 0.128, 0.183, 0.213, 0.222, 0.195, 0.157, 0.123, 0.079],
  },
  amber: {
    l: [0.987, 0.962, 0.924, 0.879, 0.828, 0.769, 0.666, 0.555, 0.473, 0.414, 0.279],
    c: [0.022, 0.059, 0.12, 0.169, 0.189, 0.188, 0.179, 0.163, 0.137, 0.112, 0.077],
  },
  yellow: {
    l: [0.987, 0.973, 0.945, 0.905, 0.852, 0.795, 0.681, 0.554, 0.476, 0.421, 0.286],
    c: [0.026, 0.071, 0.129, 0.182, 0.199, 0.184, 0.162, 0.135, 0.114, 0.095, 0.066],
  },
  lime: {
    l: [0.986, 0.967, 0.938, 0.897, 0.841, 0.768, 0.648, 0.532, 0.453, 0.405, 0.274],
    c: [0.031, 0.067, 0.127, 0.196, 0.238, 0.233, 0.2, 0.157, 0.124, 0.101, 0.072],
  },
  green: {
    l: [0.982, 0.962, 0.925, 0.871, 0.792, 0.723, 0.627, 0.527, 0.448, 0.393, 0.266],
    c: [0.018, 0.044, 0.084, 0.15, 0.209, 0.219, 0.194, 0.154, 0.119, 0.095, 0.065],
  },
  emerald: {
    l: [0.979, 0.95, 0.905, 0.845, 0.765, 0.696, 0.596, 0.508, 0.432, 0.378, 0.262],
    c: [0.021, 0.052, 0.093, 0.143, 0.177, 0.17, 0.145, 0.118, 0.095, 0.077, 0.051],
  },
  teal: {
    l: [0.984, 0.953, 0.91, 0.855, 0.777, 0.704, 0.6, 0.511, 0.437, 0.386, 0.277],
    c: [0.014, 0.051, 0.096, 0.138, 0.152, 0.14, 0.118, 0.096, 0.078, 0.063, 0.046],
  },
  cyan: {
    l: [0.984, 0.956, 0.917, 0.865, 0.789, 0.715, 0.609, 0.52, 0.45, 0.398, 0.302],
    c: [0.019, 0.045, 0.08, 0.127, 0.154, 0.143, 0.126, 0.105, 0.085, 0.07, 0.056],
  },
  sky: {
    l: [0.977, 0.951, 0.901, 0.828, 0.746, 0.685, 0.588, 0.5, 0.443, 0.391, 0.293],
    c: [0.013, 0.026, 0.058, 0.111, 0.16, 0.169, 0.158, 0.134, 0.11, 0.09, 0.066],
  },
  blue: {
    l: [0.97, 0.932, 0.882, 0.809, 0.707, 0.623, 0.546, 0.488, 0.424, 0.379, 0.282],
    c: [0.014, 0.032, 0.059, 0.105, 0.165, 0.214, 0.245, 0.243, 0.199, 0.146, 0.091],
  },
  indigo: {
    l: [0.962, 0.93, 0.87, 0.785, 0.673, 0.585, 0.511, 0.457, 0.398, 0.359, 0.257],
    c: [0.018, 0.034, 0.065, 0.115, 0.182, 0.233, 0.262, 0.24, 0.195, 0.144, 0.09],
  },
  violet: {
    l: [0.969, 0.943, 0.894, 0.811, 0.702, 0.606, 0.541, 0.491, 0.432, 0.38, 0.283],
    c: [0.016, 0.029, 0.057, 0.111, 0.183, 0.25, 0.281, 0.27, 0.232, 0.189, 0.141],
  },
  purple: {
    l: [0.977, 0.946, 0.902, 0.827, 0.714, 0.627, 0.558, 0.496, 0.438, 0.381, 0.291],
    c: [0.014, 0.033, 0.063, 0.119, 0.203, 0.265, 0.288, 0.265, 0.218, 0.176, 0.149],
  },
  fuchsia: {
    l: [0.977, 0.952, 0.903, 0.833, 0.74, 0.667, 0.591, 0.518, 0.452, 0.401, 0.293],
    c: [0.017, 0.037, 0.076, 0.145, 0.238, 0.295, 0.293, 0.253, 0.211, 0.17, 0.136],
  },
  pink: {
    l: [0.971, 0.948, 0.899, 0.823, 0.718, 0.656, 0.592, 0.525, 0.459, 0.408, 0.284],
    c: [0.014, 0.028, 0.061, 0.12, 0.202, 0.241, 0.249, 0.223, 0.187, 0.153, 0.109],
  },
  rose: {
    l: [0.969, 0.941, 0.892, 0.81, 0.712, 0.645, 0.586, 0.514, 0.455, 0.41, 0.271],
    c: [0.015, 0.03, 0.058, 0.117, 0.194, 0.246, 0.253, 0.222, 0.188, 0.159, 0.105],
  },
  slate: {
    l: [0.984, 0.968, 0.929, 0.869, 0.704, 0.554, 0.446, 0.372, 0.279, 0.208, 0.129],
    c: [0.003, 0.007, 0.013, 0.022, 0.04, 0.046, 0.043, 0.044, 0.041, 0.042, 0.042],
  },
  gray: {
    l: [0.985, 0.967, 0.928, 0.872, 0.707, 0.551, 0.446, 0.373, 0.278, 0.21, 0.13],
    c: [0.002, 0.003, 0.006, 0.01, 0.022, 0.027, 0.03, 0.034, 0.033, 0.034, 0.028],
  },
  zinc: {
    l: [0.985, 0.967, 0.92, 0.871, 0.705, 0.552, 0.442, 0.37, 0.274, 0.21, 0.141],
    c: [0.0, 0.001, 0.004, 0.006, 0.015, 0.016, 0.017, 0.013, 0.006, 0.006, 0.005],
  },
  neutral: {
    l: [0.985, 0.97, 0.922, 0.87, 0.708, 0.556, 0.439, 0.371, 0.269, 0.205, 0.145],
    c: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  },
  stone: {
    l: [0.985, 0.97, 0.923, 0.869, 0.709, 0.553, 0.444, 0.374, 0.268, 0.216, 0.147],
    c: [0.001, 0.001, 0.003, 0.005, 0.01, 0.013, 0.011, 0.01, 0.007, 0.006, 0.004],
  },
  taupe: {
    l: [0.986, 0.96, 0.922, 0.868, 0.714, 0.547, 0.438, 0.367, 0.268, 0.214, 0.147],
    c: [0.002, 0.002, 0.005, 0.007, 0.014, 0.021, 0.017, 0.016, 0.011, 0.009, 0.004],
  },
  mauve: {
    l: [0.985, 0.96, 0.922, 0.865, 0.711, 0.542, 0.435, 0.364, 0.263, 0.212, 0.145],
    c: [0.0, 0.003, 0.005, 0.012, 0.019, 0.034, 0.029, 0.029, 0.024, 0.019, 0.008],
  },
  mist: {
    l: [0.987, 0.963, 0.925, 0.872, 0.723, 0.56, 0.45, 0.378, 0.275, 0.218, 0.148],
    c: [0.002, 0.002, 0.005, 0.007, 0.014, 0.021, 0.017, 0.015, 0.011, 0.008, 0.004],
  },
  olive: {
    l: [0.988, 0.966, 0.93, 0.88, 0.737, 0.58, 0.466, 0.394, 0.286, 0.228, 0.153],
    c: [0.003, 0.005, 0.007, 0.011, 0.021, 0.031, 0.025, 0.023, 0.016, 0.013, 0.006],
  },
};

function buildTargets(values, anchor500) {
  return TONES.map((tone, i) => ({
    x: toneToX(tone),
    y: (values[i] / anchor500) * ANCHOR_Y,
  })).filter(({ x }) => Math.abs(x - ANCHOR_X) > 1e-9); // exclude anchor itself
}

function initialCurve(targets, p0y, p1y) {
  // Place handles at reasonable starting positions
  return {
    p0y,
    cp0x: 0.15,
    cp0y: p0y * 0.9,
    cpa0x: 0.35,
    cpa0y: ANCHOR_Y + (p0y - ANCHOR_Y) * 0.3,
    cpa1x: 0.65,
    cpa1y: ANCHOR_Y + (p1y - ANCHOR_Y) * 0.3,
    cp1x: 0.85,
    cp1y: p1y * 1.1,
    p1y,
  };
}

function r(n) {
  return Math.round(n * 10000) / 10000;
}

const results = {};
for (const [name, data] of Object.entries(TAILWIND)) {
  const l500 = data.l[5]; // index 5 = tone 500
  const c500 = data.c[5];

  const lTargets = buildTargets(data.l, l500);
  const cTargets = buildTargets(data.c, c500);

  const lInit = initialCurve(
    lTargets,
    (data.l[0] / l500) * ANCHOR_Y,
    (data.l[10] / l500) * ANCHOR_Y,
  );
  const cInit = initialCurve(
    cTargets,
    (data.c[0] / c500) * ANCHOR_Y,
    (data.c[10] / c500) * ANCHOR_Y,
  );

  const lCurve = fitCurve(lTargets, lInit);
  const cCurve = fitCurve(cTargets, cInit);

  const lErr = Math.sqrt(sse(lCurve, lTargets) / lTargets.length);
  const cErr = Math.sqrt(sse(cCurve, cTargets) / cTargets.length);

  results[name] = {
    lightnessCurve: {
      p0y: r(lCurve.p0y),
      cp0x: r(lCurve.cp0x),
      cp0y: r(lCurve.cp0y),
      cpa0x: r(lCurve.cpa0x),
      cpa0y: r(lCurve.cpa0y),
      cpa1x: r(lCurve.cpa1x),
      cpa1y: r(lCurve.cpa1y),
      cp1x: r(lCurve.cp1x),
      cp1y: r(lCurve.cp1y),
      p1y: r(lCurve.p1y),
    },
    chromaCurve: {
      p0y: r(cCurve.p0y),
      cp0x: r(cCurve.cp0x),
      cp0y: r(cCurve.cp0y),
      cpa0x: r(cCurve.cpa0x),
      cpa0y: r(cCurve.cpa0y),
      cpa1x: r(cCurve.cpa1x),
      cpa1y: r(cCurve.cpa1y),
      cp1x: r(cCurve.cp1x),
      cp1y: r(cCurve.cp1y),
      p1y: r(cCurve.p1y),
    },
    lRmsError: lErr.toFixed(5),
    cRmsError: cErr.toFixed(5),
  };
}

for (const [name, { lightnessCurve, chromaCurve, lRmsError, cRmsError }] of Object.entries(
  results,
)) {
  const lc = lightnessCurve;
  const cc = chromaCurve;
  process.stdout.write(
    `  { name: "${name}", ...,\n` +
      `    lightnessCurve: { p0y:${lc.p0y}, cp0x:${lc.cp0x}, cp0y:${lc.cp0y}, cpa0x:${lc.cpa0x}, cpa0y:${lc.cpa0y}, cpa1x:${lc.cpa1x}, cpa1y:${lc.cpa1y}, cp1x:${lc.cp1x}, cp1y:${lc.cp1y}, p1y:${lc.p1y} },\n` +
      `    chromaCurve:    { p0y:${cc.p0y}, cp0x:${cc.cp0x}, cp0y:${cc.cp0y}, cpa0x:${cc.cpa0x}, cpa0y:${cc.cpa0y}, cpa1x:${cc.cpa1x}, cpa1y:${cc.cpa1y}, cp1x:${cc.cp1x}, cp1y:${cc.cp1y}, p1y:${cc.p1y} },\n` +
      `    // L rms: ${lRmsError}, C rms: ${cRmsError}\n` +
      `  },\n`,
  );
}
