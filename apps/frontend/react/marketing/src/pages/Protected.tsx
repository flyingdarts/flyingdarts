import MarketingFooterNeon from "@/components/neon/MarketingFooterNeon";
import MarketingNav from "@/components/neon/MarketingNav";
import loginClient from "@/authressClient";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

const Protected = () => {
  const navigate = useNavigate();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let mounted = true;
    (async () => {
      const hasSession = await loginClient.userSessionExists();
      if (!hasSession) {
        navigate("/");
        return;
      }
      if (mounted) setReady(true);
    })();
    return () => {
      mounted = false;
    };
  }, [navigate]);

  if (!ready) return null;
  return (
    <>
      <MarketingNav />
      <main className="neon-page-main">
        <h1 className="neon-page-title">PROTECTED</h1>
        <p className="neon-page-lead">Only visible when logged in.</p>
      </main>
      <MarketingFooterNeon />
    </>
  );
};

export default Protected;
