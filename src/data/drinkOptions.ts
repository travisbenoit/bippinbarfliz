export const DRINK_CATEGORIES = [
  'Whiskey',
  'Vodka',
  'Lager Beer',
  'Craft Beer',
  'Tequila',
  'Gin',
  'Wine',
  'Rum',
  'Mezcal',
  'Mixed Drinks',
] as const;

export type DrinkCategory = typeof DRINK_CATEGORIES[number];

export const MIXED_DRINKS = [
  'Margarita',
  'Mojito',
  'Old Fashioned',
  'Martini',
  'Cosmopolitan',
  'Long Island Iced Tea',
  'Pina Colada',
  'Mai Tai',
  'Daiquiri',
  'Moscow Mule',
] as const;

export type MixedDrink = typeof MIXED_DRINKS[number];

export const formatDrinkForStorage = (category: DrinkCategory, mixedDrink?: string): string => {
  if (category === 'Mixed Drinks' && mixedDrink) {
    return `Mixed Drinks: ${mixedDrink}`;
  }
  return category;
};

export const parseDrinkFromStorage = (drink: string): { category: DrinkCategory; mixedDrink?: string } => {
  if (drink.startsWith('Mixed Drinks: ')) {
    return {
      category: 'Mixed Drinks',
      mixedDrink: drink.replace('Mixed Drinks: ', ''),
    };
  }
  return { category: drink as DrinkCategory };
};
