import BetaStripNeon from "@/components/neon/BetaStripNeon";
import BetaTestersNeon from "@/components/neon/BetaTestersNeon";
import HeroNeon from "@/components/neon/HeroNeon";
import LandingFeatures from "@/components/neon/LandingFeatures";
import MarketingFooterNeon from "@/components/neon/MarketingFooterNeon";
import MarketingNav from "@/components/neon/MarketingNav";

const Index = () => {
  return (
    <>
      <MarketingNav />
      <main>
        <HeroNeon />
        <BetaStripNeon />
        <LandingFeatures />
        <BetaTestersNeon />
      </main>
      <MarketingFooterNeon />
    </>
  );
};

export default Index;
