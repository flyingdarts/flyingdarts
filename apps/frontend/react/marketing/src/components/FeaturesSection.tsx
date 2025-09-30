import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { getImplementedFeatures } from "@/data/features";
import { ArrowRight, Mic, Plus, Shield, Target, TrendingUp, Users } from "lucide-react";
import { Link } from "react-router-dom";

const FeaturesSection = () => {
  const implementedFeatures = getImplementedFeatures();
  
  const getIcon = (iconName: string) => {
    const iconMap: { [key: string]: JSX.Element } = {
      Users: <Users className="w-8 h-8" />,
      Target: <Target className="w-8 h-8" />,
      Mic: <Mic className="w-8 h-8" />,
      Shield: <Shield className="w-8 h-8" />,
      TrendingUp: <TrendingUp className="w-8 h-8" />,
    };
    return iconMap[iconName] || <Users className="w-8 h-8" />;
  };

  return (
    <section id="features" className="py-24 relative overflow-hidden">
      <div className="container mx-auto px-6">
        <div className="text-center mb-16">
          <h2 className="text-4xl lg:text-5xl font-bold mb-6">
            Why Choose 
            <span className="text-white drop-shadow-lg"> Flyingdarts</span>
          </h2>
          <p className="text-xl text-muted-foreground max-w-3xl mx-auto">
            Experience the perfect blend of traditional darts and cutting-edge technology. 
            Every feature designed to enhance your gaming experience.
          </p>
        </div>
        
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {implementedFeatures.map((feature, index) => (
            <Card 
              key={index} 
              className="group hover:border-primary/50 transition-all duration-300 hover:shadow-[0_0_30px_hsl(var(--primary)/0.3)] bg-card/50 backdrop-blur-sm"
            >
              <CardHeader>
                <div className="text-primary group-hover:text-accent transition-colors duration-300 mb-4">
                  {getIcon(feature.iconName)}
                </div>
                <CardTitle className="text-xl">{feature.title}</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-muted-foreground leading-relaxed">
                  {feature.description}
                </p>
              </CardContent>
            </Card>
          ))}
          
          {/* Link card to features page */}
          <Card className="group hover:border-primary/50 transition-all duration-300 hover:shadow-[0_0_30px_hsl(var(--primary)/0.3)] bg-card/50 backdrop-blur-sm border-dashed border-2">
            <CardHeader>
              <div className="text-primary group-hover:text-accent transition-colors duration-300 mb-4 flex justify-center">
                <Plus className="w-8 h-8" />
              </div>
              <CardTitle className="text-xl text-center">More Features</CardTitle>
            </CardHeader>
            <CardContent className="text-center">
              <p className="text-muted-foreground leading-relaxed mb-4">
                Discover upcoming features and planned improvements for Flyingdarts.
              </p>
              <Button asChild variant="outline" className="group-hover:bg-primary group-hover:text-primary-foreground transition-colors">
                <Link to="/features" className="flex items-center gap-2">
                  View All Features
                  <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                </Link>
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  );
};

export default FeaturesSection;