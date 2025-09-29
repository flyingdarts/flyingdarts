export interface Feature {
  iconName: string;
  title: string;
  description: string;
  implemented: boolean;
  comingSoon?: boolean;
}

export const features: Feature[] = [
  // Implemented features
  {
    iconName: "Users",
    title: "Friends",
    description: "Add friends, see who's online, and invite them to play. Create public rooms where any friend can join—stay connected and keep the rivalry going.",
    implemented: true,
  },
  {
    iconName: "Target",
    title: "X01 public games",
    description: "Play classic X01 (501) in public games with fair play and live scoring.",
    implemented: true,
  },
  {
    iconName: "Mic",
    title: "iOS scoring app",
    description: "Input scores hands‑free with speech‑to‑text on your iPhone or iPad. Fast, accurate voice scoring keeps you focused on the board.",
    implemented: true,
  },
  {
    iconName: "Shield",
    title: "Fair Play",
    description: "Advanced anti-cheat systems and fair matchmaking ensure every game is competitive and enjoyable for all skill levels.",
    implemented: true,
  },
  {
    iconName: "TrendingUp",
    title: "Performance Analytics",
    description: "Detailed statistics, progress tracking, and personalized insights to help you improve your game and reach new skill levels.",
    implemented: true,
  },
  
  // Planned features
  {
    iconName: "Gamepad2",
    title: "Other game modes",
    description: "More ways to play are on the way.",
    implemented: false,
    comingSoon: true,
  },
  {
    iconName: "Clock",
    title: "Queues",
    description: "Smart matchmaking queues for faster games.",
    implemented: false,
    comingSoon: true,
  },
  {
    iconName: "Trophy",
    title: "Tournaments",
    description: "Compete in brackets, seasons, and events.",
    implemented: false,
    comingSoon: true,
  },
  {
    iconName: "Eye",
    title: "Spectate mode",
    description: "Watch live games and follow top players.",
    implemented: false,
    comingSoon: true,
  },
];

export const getImplementedFeatures = (): Feature[] => {
  return features.filter(feature => feature.implemented);
};

export const getPlannedFeatures = (): Feature[] => {
  return features.filter(feature => !feature.implemented);
};
