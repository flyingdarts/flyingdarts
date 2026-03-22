import MarketingFooterNeon from "@/components/neon/MarketingFooterNeon";
import MarketingNav from "@/components/neon/MarketingNav";

const Community = () => {
  return (
    <>
      <MarketingNav />
      <main className="neon-page-main">
        <div className="neon-section-label" style={{ justifyContent: "center" }}>
          Connect
        </div>
        <h1 className="neon-page-title">COMMUNITY</h1>
        <p className="neon-page-lead">
          Connect with other players, share tips, and stay up to date with the latest FlyingDarts news.
        </p>
        <div style={{ textAlign: "center" }}>
          <a href="https://discord.gg/SyFzsEbfsk" className="neon-community-cta" target="_blank" rel="noreferrer">
            Join us on Discord
          </a>
        </div>
      </main>
      <MarketingFooterNeon />
    </>
  );
};

export default Community;
