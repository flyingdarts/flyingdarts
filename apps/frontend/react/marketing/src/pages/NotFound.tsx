import MarketingFooterNeon from "@/components/neon/MarketingFooterNeon";
import MarketingLayout from "@/components/neon/MarketingLayout";
import MarketingNav from "@/components/neon/MarketingNav";
import { Link, useLocation } from "react-router-dom";
import { useEffect } from "react";

const NotFound = () => {
  const location = useLocation();

  useEffect(() => {
    console.error("404 Error: User attempted to access non-existent route:", location.pathname);
  }, [location.pathname]);

  return (
    <MarketingLayout>
      <MarketingNav />
      <main className="neon-page-main" style={{ minHeight: "60vh", display: "flex", flexDirection: "column", justifyContent: "center" }}>
        <h1 className="neon-page-title">404</h1>
        <p className="neon-page-lead">Page not found.</p>
        <div style={{ textAlign: "center" }}>
          <Link to="/" className="neon-community-cta">
            Return home
          </Link>
        </div>
      </main>
      <MarketingFooterNeon />
    </MarketingLayout>
  );
};

export default NotFound;
