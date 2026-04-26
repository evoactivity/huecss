import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { modifier } from "ember-modifier";
import type { BezierCurve } from "#utils/spline";
import {
  bezierSvgPath,
  evaluateBezier,
  toneToX,
  DEFAULT_LIGHTNESS_CURVE,
  ANCHOR_X,
  ANCHOR_Y,
} from "#utils/spline";
import type { ColourToken } from "#utils/token-generator";
import styles from "./spline-editor.module.css";

const SVG_W = 800;
const SVG_H = 600;
const CURVE_PAD = 160;
const POINT_R = 7;
const HANDLE_R = 5;
const ANCHOR_R = 6;
const TONE_DOT_R = 5;

type DragTarget = "p0" | "p1" | "cp0" | "cpa0" | "cpa1" | "cp1";

interface ToneMarker {
  x: number;
  y: number;
  size: number;
  fill: string;
  isAnchor: boolean;
}

interface Signature {
  Args: {
    label: string;
    curve?: BezierCurve;
    onChange: (curve: BezierCurve) => void;
    tokens?: ColourToken[];
  };
}

export default class SplineEditor extends Component<Signature> {
  private dragging: DragTarget | null = null;
  private dragOffsetX = 0;
  private dragOffsetY = 0;
  private svgEl: SVGSVGElement | null = null;

  get curve(): BezierCurve {
    return this.args.curve ?? DEFAULT_LIGHTNESS_CURVE;
  }

  get curvePath(): string {
    return bezierSvgPath(this.curve, SVG_W, SVG_H, CURVE_PAD);
  }

  private svgX(x: number): number {
    return CURVE_PAD + x * (SVG_W - 2 * CURVE_PAD);
  }
  private svgY(y: number): number {
    return CURVE_PAD + (1 - y) * (SVG_H - 2 * CURVE_PAD);
  }
  private fromSvgX(sx: number): number {
    return (sx - CURVE_PAD) / (SVG_W - 2 * CURVE_PAD);
  }
  private fromSvgY(sy: number): number {
    return 1 - (sy - CURVE_PAD) / (SVG_H - 2 * CURVE_PAD);
  }

  get p0x(): number {
    return this.svgX(0);
  }
  get p0y(): number {
    return this.svgY(this.curve.p0y);
  }
  get p1x(): number {
    return this.svgX(1);
  }
  get p1y(): number {
    return this.svgY(this.curve.p1y);
  }
  get cp0x(): number {
    return this.svgX(this.curve.cp0x);
  }
  get cp0y(): number {
    return this.svgY(this.curve.cp0y);
  }
  get cpa0x(): number {
    return this.svgX(this.curve.cpa0x);
  }
  get cpa0y(): number {
    return this.svgY(this.curve.cpa0y);
  }
  get cpa1x(): number {
    return this.svgX(this.curve.cpa1x);
  }
  get cpa1y(): number {
    return this.svgY(this.curve.cpa1y);
  }
  get cp1x(): number {
    return this.svgX(this.curve.cp1x);
  }
  get cp1y(): number {
    return this.svgY(this.curve.cp1y);
  }
  get anchorSvgX(): number {
    return this.svgX(ANCHOR_X);
  }
  get anchorSvgY(): number {
    return this.svgY(ANCHOR_Y);
  }

  get gridLines(): Array<{ d: string; axis: boolean }> {
    const ticks = [0, 0.25, 0.5, 0.75, 1];
    const lines: Array<{ d: string; axis: boolean }> = [];
    const x0 = this.svgX(0);
    const x1 = this.svgX(1);
    const y0 = this.svgY(0);
    const y1 = this.svgY(1);
    for (const t of ticks) {
      const sy = this.svgY(t);
      lines.push({ d: `M${x0},${sy} L${x1},${sy}`, axis: t === 0 || t === 1 });
      const sx = this.svgX(t);
      lines.push({ d: `M${sx},${y1} L${sx},${y0}`, axis: t === 0 || t === 1 });
    }
    return lines;
  }

  // Handle lines: p0->cp0, cpa0->anchor, anchor->cpa1, cp1->p1
  get handleLine0(): string {
    return `M${this.p0x},${this.p0y} L${this.cp0x},${this.cp0y}`;
  }
  get handleLineA0(): string {
    return `M${this.anchorSvgX},${this.anchorSvgY} L${this.cpa0x},${this.cpa0y}`;
  }
  get handleLineA1(): string {
    return `M${this.anchorSvgX},${this.anchorSvgY} L${this.cpa1x},${this.cpa1y}`;
  }
  get handleLine1(): string {
    return `M${this.p1x},${this.p1y} L${this.cp1x},${this.cp1y}`;
  }

  get toneMarkers(): ToneMarker[] {
    const tokens = this.args.tokens;
    if (!tokens) return [];
    return tokens.map((token) => {
      const x = toneToX(token.tone);
      const curveY = evaluateBezier(this.curve, x);
      const isAnchor = token.tone === 500;
      const size = isAnchor ? ANCHOR_R * 2 : TONE_DOT_R * 2;
      const cx = this.svgX(x);
      const cy = this.svgY(curveY);
      return {
        x: cx - size / 2,
        y: cy - size / 2,
        size,
        fill: `oklch(${token.l} ${token.c} ${token.h})`,
        isAnchor,
      };
    });
  }

  registerSvg = modifier((el: SVGSVGElement) => {
    this.svgEl = el;
    return () => {
      this.svgEl = null;
    };
  });

  private clientToSvg(clientX: number, clientY: number): { sx: number; sy: number } | null {
    const svg = this.svgEl;
    if (!svg) return null;
    const pt = svg.createSVGPoint();
    pt.x = clientX;
    pt.y = clientY;
    const ctm = svg.getScreenCTM();
    if (!ctm) return null;
    const svgPt = pt.matrixTransform(ctm.inverse());
    return { sx: svgPt.x, sy: svgPt.y };
  }

  private clampToSvgBounds(sx: number, sy: number): { sx: number; sy: number } {
    const svg = this.svgEl;
    const margin = HANDLE_R;
    let minX = margin,
      maxX = SVG_W - margin;
    let minY = margin,
      maxY = SVG_H - margin;
    if (svg) {
      const ctm = svg.getScreenCTM();
      const rect = svg.getBoundingClientRect();
      if (ctm) {
        const toSvg = ctm.inverse();
        const pt = svg.createSVGPoint();
        pt.x = rect.left;
        pt.y = rect.top;
        const tl = pt.matrixTransform(toSvg);
        pt.x = rect.right;
        pt.y = rect.bottom;
        const br = pt.matrixTransform(toSvg);
        minX = tl.x + margin;
        maxX = br.x - margin;
        minY = tl.y + margin;
        maxY = br.y - margin;
      }
    }
    return {
      sx: Math.min(maxX, Math.max(minX, sx)),
      sy: Math.min(maxY, Math.max(minY, sy)),
    };
  }

  private startDrag(event: PointerEvent): void {
    const target = (event.currentTarget as Element).id as DragTarget;
    if (!target) return;
    this.dragging = target;
    const pos = this.clientToSvg(event.clientX, event.clientY);
    if (pos) {
      const c = this.curve;
      const mx = this.fromSvgX(pos.sx);
      const my = this.fromSvgY(pos.sy);
      switch (target) {
        case "p0":
          this.dragOffsetX = 0;
          this.dragOffsetY = my - c.p0y;
          break;
        case "p1":
          this.dragOffsetX = 0;
          this.dragOffsetY = my - c.p1y;
          break;
        case "cp0":
          this.dragOffsetX = mx - c.cp0x;
          this.dragOffsetY = my - c.cp0y;
          break;
        case "cpa0":
          this.dragOffsetX = mx - c.cpa0x;
          this.dragOffsetY = my - c.cpa0y;
          break;
        case "cpa1":
          this.dragOffsetX = mx - c.cpa1x;
          this.dragOffsetY = my - c.cpa1y;
          break;
        case "cp1":
          this.dragOffsetX = mx - c.cp1x;
          this.dragOffsetY = my - c.cp1y;
          break;
      }
    }
    (event.currentTarget as Element).setPointerCapture(event.pointerId);
  }

  private applyDrag(event: PointerEvent): void {
    if (!this.dragging) return;
    const pos = this.clientToSvg(event.clientX, event.clientY);
    if (!pos) return;
    const clamped = this.clampToSvgBounds(pos.sx, pos.sy);
    const x = this.fromSvgX(clamped.sx) - this.dragOffsetX;
    const y = this.fromSvgY(clamped.sy) - this.dragOffsetY;
    const c = this.curve;
    const clampY = (v: number) => Math.min(1, Math.max(0, v));
    switch (this.dragging) {
      case "p0":
        this.args.onChange({ ...c, p0y: clampY(y) });
        break;
      case "p1":
        this.args.onChange({ ...c, p1y: clampY(y) });
        break;
      case "cp0":
        this.args.onChange({ ...c, cp0x: Math.min(ANCHOR_X, x), cp0y: y });
        break;
      case "cpa0":
        this.args.onChange({ ...c, cpa0x: Math.min(ANCHOR_X, x), cpa0y: y });
        break;
      case "cpa1":
        this.args.onChange({ ...c, cpa1x: Math.max(ANCHOR_X, x), cpa1y: y });
        break;
      case "cp1":
        this.args.onChange({ ...c, cp1x: Math.max(ANCHOR_X, x), cp1y: y });
        break;
    }
  }

  @action onPointerDown(e: PointerEvent): void {
    e.stopPropagation();
    this.startDrag(e);
  }

  @action onPointerMove(e: PointerEvent): void {
    this.applyDrag(e);
  }
  @action onPointerUp(): void {
    this.dragging = null;
  }

  <template>
    <div class={{styles.wrapper}}>
      <span class={{styles.label}}>{{@label}}</span>
      <svg
        class={{styles.svg}}
        viewBox="0 0 {{SVG_W}} {{SVG_H}}"
        {{this.registerSvg}}
        {{on "pointermove" this.onPointerMove}}
        {{on "pointerup" this.onPointerUp}}
      >
        {{! Grid }}
        {{#each this.gridLines as |line|}}
          <path class="{{if line.axis styles.gridAxis styles.gridLine}}" d={{line.d}} />
        {{/each}}

        {{! Curve }}
        <path class={{styles.curve}} d={{this.curvePath}} />

        {{! Tone squares }}
        {{#each this.toneMarkers as |marker|}}
          <rect
            class="{{styles.toneDot}} {{if marker.isAnchor styles.toneDotAnchor}}"
            x={{marker.x}}
            y={{marker.y}}
            width={{marker.size}}
            height={{marker.size}}
            style="fill: {{marker.fill}}"
          />
        {{/each}}

        {{! Fallback anchor when no tokens are provided }}
        {{#unless @tokens}}
          <circle
            class={{styles.anchor}}
            cx={{this.anchorSvgX}}
            cy={{this.anchorSvgY}}
            r={{ANCHOR_R}}
          />
        {{/unless}}

        {{! Handle lines always on top }}
        <path class={{styles.handleLine}} d={{this.handleLine0}} />
        <path class={{styles.handleLine}} d={{this.handleLineA0}} />
        <path class={{styles.handleLine}} d={{this.handleLineA1}} />
        <path class={{styles.handleLine}} d={{this.handleLine1}} />

        {{! Outer handles (near endpoints) }}
        <circle
          id="cp0"
          class={{styles.handle}}
          cx={{this.cp0x}}
          cy={{this.cp0y}}
          r={{HANDLE_R}}
          {{on "pointerdown" this.onPointerDown}}
        />
        <circle
          id="cp1"
          class={{styles.handle}}
          cx={{this.cp1x}}
          cy={{this.cp1y}}
          r={{HANDLE_R}}
          {{on "pointerdown" this.onPointerDown}}
        />

        {{! Inner handles (near anchor) }}
        <circle
          id="cpa0"
          class={{styles.handle}}
          cx={{this.cpa0x}}
          cy={{this.cpa0y}}
          r={{HANDLE_R}}
          {{on "pointerdown" this.onPointerDown}}
        />
        <circle
          id="cpa1"
          class={{styles.handle}}
          cx={{this.cpa1x}}
          cy={{this.cpa1y}}
          r={{HANDLE_R}}
          {{on "pointerdown" this.onPointerDown}}
        />

        {{! Endpoint points (y-only drag) }}
        <circle
          id="p0"
          class={{styles.point}}
          cx={{this.p0x}}
          cy={{this.p0y}}
          r={{POINT_R}}
          {{on "pointerdown" this.onPointerDown}}
        />
        <circle
          id="p1"
          class={{styles.point}}
          cx={{this.p1x}}
          cy={{this.p1y}}
          r={{POINT_R}}
          {{on "pointerdown" this.onPointerDown}}
        />
      </svg>
      <span class={{styles.hint}}>Drag endpoints up/down, drag handles to adjust curve shape</span>
    </div>
  </template>
}
