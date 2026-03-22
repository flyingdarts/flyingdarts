export default function BetaStripNeon() {
  return (
    <div className="neon-beta-strip neon-beta-strip--tight" id="roadmap">
      <div className="neon-strip-icon">⚠</div>
      <div className="neon-strip-text">
        <h3>This is a beta product</h3>
        <p>
          FlyingDarts is actively being built. You may encounter bugs, missing features, and breaking changes. Your
          feedback directly shapes what we build next. <strong>Beta testers get lifetime Pro access.</strong>
        </p>
      </div>
      <a className="neon-strip-action" href="https://game.flyingdarts.net">
        View Roadmap →
      </a>
    </div>
  );
}
