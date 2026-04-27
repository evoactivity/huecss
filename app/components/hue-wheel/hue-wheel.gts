import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { modifier } from "ember-modifier";
import { htmlSafe } from "@ember/template";
import type { SafeString } from "@ember/template";
import styles from "./hue-wheel.module.css";

// SVG coordinate space
const CX = 100;
const CY = 100;
const OUTER_R = 90;
const INNER_R = 68; // inner edge of the hue ring segments
const CENTRE_R = 62; // radius of the current colour circle -- gap between them
const INDICATOR_R = 5;
// Number of segments used to approximate the hue ring
const SEGMENTS = 360;

interface Signature {
  Args: {
    hue: number; // 0-360
    lightness: number; // 0-1, used for swatch brightness
    chroma: number; // 0+, used for swatch saturation
    onChange: (hue: number) => void;
  };
}

export default class HueWheel extends Component<Signature> {
  private svgEl: SVGSVGElement | null = null;
  private isDragging = false;

  registerSvg = modifier((el: SVGSVGElement) => {
    this.svgEl = el;
    return () => {
      this.svgEl = null;
    };
  });

  // Build the hue ring as a series of pie slices, each filled with its hue colour.
  get segments(): Array<{ d: string; fill: string }> {
    const segs: Array<{ d: string; fill: string }> = [];
    const step = 360 / SEGMENTS;
    const OVERLAP = 0.01; // radians of extra arc on the trailing edge

    for (let i = 0; i < SEGMENTS; i++) {
      const a0 = ((i * step - 90) * Math.PI) / 180;
      const a1 = (((i + 1) * step - 90) * Math.PI) / 180 + OVERLAP;

      const x0o = CX + OUTER_R * Math.cos(a0);
      const y0o = CY + OUTER_R * Math.sin(a0);
      const x1o = CX + OUTER_R * Math.cos(a1);
      const y1o = CY + OUTER_R * Math.sin(a1);
      const x0i = CX + INNER_R * Math.cos(a0);
      const y0i = CY + INNER_R * Math.sin(a0);
      const x1i = CX + INNER_R * Math.cos(a1);
      const y1i = CY + INNER_R * Math.sin(a1);

      const d = [
        `M${x0o.toFixed(2)},${y0o.toFixed(2)}`,
        `A${OUTER_R},${OUTER_R} 0 0,1 ${x1o.toFixed(2)},${y1o.toFixed(2)}`,
        `L${x1i.toFixed(2)},${y1i.toFixed(2)}`,
        `A${INNER_R},${INNER_R} 0 0,0 ${x0i.toFixed(2)},${y0i.toFixed(2)}`,
        "Z",
      ].join(" ");

      segs.push({ d, fill: `oklch(${this.args.lightness} ${this.args.chroma} ${i * step})` });
    }
    return segs;
  }

  // Indicator dot position on the ring at the current hue
  get indicatorX(): number {
    const angle = ((this.args.hue - 90) * Math.PI) / 180;
    return CX + ((OUTER_R + INNER_R) / 2) * Math.cos(angle);
  }
  get indicatorY(): number {
    const angle = ((this.args.hue - 90) * Math.PI) / 180;
    return CY + ((OUTER_R + INNER_R) / 2) * Math.sin(angle);
  }

  get centreStyle(): SafeString {
    return htmlSafe(`fill: oklch(${this.args.lightness} ${this.args.chroma} ${this.args.hue})`);
  }

  // Indicator focus ring radius -- slightly larger than the dot
  get focusRingR(): number {
    return INDICATOR_R + 3;
  }

  private pickHueFromEvent(event: PointerEvent): void {
    const svg = this.svgEl;
    if (!svg) return;
    const pt = svg.createSVGPoint();
    pt.x = event.clientX;
    pt.y = event.clientY;
    const ctm = svg.getScreenCTM();
    if (!ctm) return;
    const svgPt = pt.matrixTransform(ctm.inverse());
    const dx = svgPt.x - CX;
    const dy = svgPt.y - CY;
    let hue = (Math.atan2(dy, dx) * 180) / Math.PI + 90;
    if (hue < 0) hue += 360;
    if (hue >= 360) hue -= 360;
    this.args.onChange(Math.round(hue * 10) / 10);
  }

  onPointerDown = (e: PointerEvent): void => {
    this.isDragging = true;
    (e.currentTarget as Element).setPointerCapture(e.pointerId);
    this.pickHueFromEvent(e);
  };

  onPointerMove = (e: PointerEvent): void => {
    if (!this.isDragging) return;
    this.pickHueFromEvent(e);
  };

  onPointerUp = (): void => {
    this.isDragging = false;
  };

  onSliderInput = (e: Event): void => {
    this.args.onChange(parseFloat((e.target as HTMLInputElement).value));
  };

  <template>
    <div class={{styles.wrapper}}>
      <svg
        class={{styles.svg}}
        viewBox="0 0 200 200"
        aria-hidden="true"
        {{this.registerSvg}}
        {{on "pointermove" this.onPointerMove}}
        {{on "pointerup" this.onPointerUp}}
      >
        {{! Ring segments -- pointer events restricted to this group only }}
        <g class={{styles.ring}} {{on "pointerdown" this.onPointerDown}}>
          {{#each this.segments as |seg|}}
            <path d={{seg.d}} fill={{seg.fill}} />
          {{/each}}
        </g>

        {{! Centre swatch showing current colour }}
        <circle cx={{CX}} cy={{CY}} r={{CENTRE_R}} style={{this.centreStyle}} />

        {{! Focus ring -- visible via focus-within on .wrapper }}
        <circle
          class={{styles.focusRing}}
          cx={{this.indicatorX}}
          cy={{this.indicatorY}}
          r={{this.focusRingR}}
          fill="none"
        />

        {{! Indicator dot at selected hue }}
        <circle
          class={{styles.indicator}}
          cx={{this.indicatorX}}
          cy={{this.indicatorY}}
          r={{INDICATOR_R}}
          fill="white"
          stroke="oklch(0 0 0 / 0.5)"
          stroke-width="1.5"
        />
      </svg>

      {{! Visually hidden range input for keyboard accessibility }}
      <input
        class={{styles.srOnly}}
        type="range"
        min="0"
        max="359"
        step="1"
        value={{this.args.hue}}
        aria-label="Hue"
        {{on "input" this.onSliderInput}}
      />
    </div>
  </template>
}
