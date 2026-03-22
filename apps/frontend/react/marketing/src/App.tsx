import { Toaster as Sonner } from "@/components/ui/sonner";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import MarketingLayout from "./components/neon/MarketingLayout";
import Community from "./pages/Community";
import Features from "./pages/Features";
import Index from "./pages/Index";
import NotFound from "./pages/NotFound";
import Protected from "./pages/Protected";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          <Route
            path="/"
            element={
              <MarketingLayout>
                <Index />
              </MarketingLayout>
            }
          />
          <Route
            path="/features"
            element={
              <MarketingLayout>
                <Features />
              </MarketingLayout>
            }
          />
          <Route
            path="/community"
            element={
              <MarketingLayout>
                <Community />
              </MarketingLayout>
            }
          />
          <Route
            path="/protected"
            element={
              <MarketingLayout>
                <Protected />
              </MarketingLayout>
            }
          />
          {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
