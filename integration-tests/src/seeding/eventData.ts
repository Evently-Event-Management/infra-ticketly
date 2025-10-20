export const eventTitles = [
  "Annual Tech Summit Sri Lanka",
  "Colombo Jazz Festival",
  "Sri Lankan Heritage Exhibition",
  "Kandy Esala Perahera Cultural Show",
  "Digital Marketing Conference",
  "Beach Volleyball Championship",
  "Sri Lankan Food Festival",
  "Startup Weekend Colombo",
  "International Film Festival",
  "Ayurveda & Wellness Retreat",
  "Tropical Wildlife Photography Exhibition",
  "Ceylon Tea Celebration",
  "Galle Literary Festival",
  "Sri Lankan Fashion Week",
  "EDM Night: Tropical Beats",
  "Cricket Tournament Finals",
  "Handloom & Craft Market",
  "Sacred Temple Music Concert",
  "Environmental Conservation Summit",
  "Traditional Dance Performance",
  "Buddhist Art Exhibition",
  "Entrepreneurship Masterclass",
  "South Asian Poetry Slam",
  "Colombo Night Market",
  "Gems & Jewelry Exhibition",
  "Vesak Lantern Festival",
  "Eco-Tourism Conference",
  "Jaffna Cultural Celebration",
  "International Yoga Day Event",
  "Marine Conservation Awareness Day"
];

export const eventCategories = [
  { id: "08b80f14-421a-41fb-8c8e-bc74d4bb1b31", name: "Music Festivals" },
  { id: "24ef0d97-9273-4c9b-a12f-8e4c21a10a5d", name: "Tech Conferences" },
  { id: "67d12c8f-ebf3-4821-b4f1-e786f4b34b65", name: "Art Exhibitions" },
  { id: "ab3e4912-6af9-4c92-9e29-f83ba71f3101", name: "Cultural Events" },
  { id: "14b2c687-f35d-48f2-8208-3aa688e165d0", name: "Food & Drink" },
  { id: "92d5e819-7ba9-4c2f-a52b-d2f234c0d8e7", name: "Sports" },
  { id: "37a0f9c5-ea81-4e9d-a16b-e4b1fdb8a367", name: "Business & Networking" },
  { id: "f9c1d368-7b24-4e42-8021-9bf5e39a4bcd", name: "Workshops" },
  { id: "c8e74b2d-d93a-46c0-af2d-9132c89ebd0e", name: "Wellness & Health" },
  { id: "5a0d1f6e-9c47-4b1e-8e9a-0e5a7cd3c36f", name: "Environmental" }
];

export const getRandomEventDescription = (title: string): string => {
  return `Join us for ${title} - a unique experience bringing together people from all walks of life. This event features special guests, interactive activities, and unforgettable memories. Don't miss this opportunity to be part of something extraordinary in beautiful Sri Lanka.`;
};

export const getRandomEventOverview = (title: string): string => {
  return `${title} is designed to provide participants with an enriching experience that celebrates the unique cultural and natural heritage of Sri Lanka. From engaging activities to networking opportunities, this event offers something for everyone.`;
};