import { type RefObject, useLayoutEffect } from "react";

/** Custom neon cursor when motion is OK and pointer is fine (mouse). */
export function useNeonCursor(rootRef: RefObject<HTMLDivElement | null>) {
  useLayoutEffect(() => {
    const root = rootRef.current;
    if (!root) return;

    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
    const finePointer = window.matchMedia("(pointer: fine)");
    if (reduceMotion.matches || !finePointer.matches) return;

    root.classList.add("neon-site--fine-pointer");

    const cursor = document.getElementById("neon-cursor-dot");
    const ring = document.getElementById("neon-cursor-ring");
    if (!cursor || !ring) return;

    let mx = 0,
      my = 0,
      rx = 0,
      ry = 0;
    let raf = 0;

    const onMove = (e: MouseEvent) => {
      mx = e.clientX;
      my = e.clientY;
      cursor.style.transform = `translate(${mx - 5}px, ${my - 5}px)`;

      const trail = document.createElement("div");
      trail.className = "neon-cursor-trail";
      trail.style.cssText = [
        "position:fixed",
        "width:4px",
        "height:4px",
        "border-radius:50%",
        "background:#00f5ff",
        "pointer-events:none",
        "z-index:9997",
        `left:${mx - 2}px`,
        `top:${my - 2}px`,
        "box-shadow:0 0 6px #00f5ff",
        "transition:opacity 0.4s,transform 0.4s",
        "opacity:0.7",
      ].join(";");
      document.body.appendChild(trail);
      requestAnimationFrame(() => {
        trail.style.opacity = "0";
        trail.style.transform = "scale(0)";
      });
      setTimeout(() => trail.remove(), 400);
    };

    function animRing() {
      rx += (mx - rx - 16) * 0.12;
      ry += (my - ry - 16) * 0.12;
      ring.style.transform = `translate(${rx}px, ${ry}px)`;
      raf = requestAnimationFrame(animRing);
    }

    window.addEventListener("mousemove", onMove);
    raf = requestAnimationFrame(animRing);

    return () => {
      root.classList.remove("neon-site--fine-pointer");
      window.removeEventListener("mousemove", onMove);
      cancelAnimationFrame(raf);
    };
  }, [rootRef]);
}

