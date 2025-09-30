import Footer from "@/components/Footer";
import Navigation from "@/components/Navigation";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { getImplementedFeatures, getPlannedFeatures } from "@/data/features";
import { Clock, Eye, Gamepad2, Mic, Shield, Target, TrendingUp, Trophy, Users } from "lucide-react";

const Features = () => {
  const implementedFeatures = getImplementedFeatures();
  const plannedFeatures = getPlannedFeatures();
  
  const getIcon = (iconName: string) => {
    const iconMap: { [key: string]: JSX.Element } = {
      Users: <Users className="w-8 h-8" />,
      Target: <Target className="w-8 h-8" />,
      Mic: <Mic className="w-8 h-8" />,
      Shield: <Shield className="w-8 h-8" />,
      TrendingUp: <TrendingUp className="w-8 h-8" />,
      Gamepad2: <Gamepad2 className="w-8 h-8" />,
      Clock: <Clock className="w-8 h-8" />,
      Trophy: <Trophy className="w-8 h-8" />,
      Eye: <Eye className="w-8 h-8" />,
    };
    return iconMap[iconName] || <Users className="w-8 h-8" />;
  };

  return (
    <div className="min-h-screen">
      <Navigation />
      <main className="container mx-auto px-6 pt-28 pb-20">
        <div className="text-center max-w-2xl mx-auto mb-12">
          <h1 className="text-4xl lg:text-5xl font-bold mb-4">Features</h1>
          <p className="text-lg text-muted-foreground">
            What you can play and how you can connect—built for fun, competition, and community.
          </p>
        </div>

        {/* Implemented Features Section */}
        <div className="mb-16">
          <h2 className="text-3xl font-bold mb-8 text-center">
            Available Now
          </h2>
          <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
            {implementedFeatures.map((feature, index) => (
              <Card
                key={`implemented-${index}`}
                className="group hover:border-primary/50 transition-all duration-300 hover:shadow-[0_0_30px_hsl(var(--primary)/0.25)] bg-card/80 backdrop-blur-sm border border-border/20 shadow-lg"
              >
                <CardHeader>
                  <div className="text-primary group-hover:text-accent transition-colors duration-300 mb-4">
                    {getIcon(feature.iconName)}
                  </div>
                  <CardTitle className="text-xl">{feature.title}</CardTitle>
                  <Badge variant="default" className="mt-2 w-fit bg-green-600 hover:bg-green-700">
                    Available
                  </Badge>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground leading-relaxed">{feature.description}</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>

        {/* Planned Features Section */}
        <div>
          <h2 className="text-3xl font-bold mb-8 text-center">
            Coming Soon
          </h2>
          <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
            {plannedFeatures.map((feature, index) => (
              <Card
                key={`planned-${index}`}
                className="group hover:border-primary/50 transition-all duration-300 hover:shadow-[0_0_30px_hsl(var(--primary)/0.25)] bg-card/80 backdrop-blur-sm border border-border/20 shadow-lg opacity-75"
              >
                <CardHeader>
                  <div className="text-primary group-hover:text-accent transition-colors duration-300 mb-4">
                    {getIcon(feature.iconName)}
                  </div>
                  <CardTitle className="text-xl">{feature.title}</CardTitle>
                  <Badge variant="secondary" className="mt-2 w-fit">
                    Coming soon
                  </Badge>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground leading-relaxed">{feature.description}</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default Features;


