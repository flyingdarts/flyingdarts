import { type ReactNode, useRef } from "react";
import { useNeonCursor } from "./useNeonCursor";
import BetaTape from "./BetaTape";
import NeonOrbs from "./NeonOrbs";

export default function MarketingLayout({ children }: { children: ReactNode }) {
  const rootRef = useRef<HTMLDivElement>(null);
  useNeonCursor(rootRef);

  return (
    <div ref={rootRef} className="neon-site">
      <div className="neon-cursor" id="neon-cursor-dot" aria-hidden />
      <div className="neon-cursor-ring" id="neon-cursor-ring" aria-hidden />
      <NeonOrbs />
      <BetaTape />
      {children}
    </div>
  );
}
