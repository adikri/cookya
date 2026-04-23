import Foundation

struct CatalogItem: Identifiable, Hashable {
    let name: String
    let category: InventoryCategory
    let defaultQuantityText: String

    var id: String { name.lowercased() }

    func asKnownItem() -> KnownInventoryItem {
        KnownInventoryItem(
            name: name,
            defaultCategory: category,
            lastQuantityText: defaultQuantityText,
            lastSource: .pantry
        )
    }
}

enum PantryItemCatalog {
    static let all: [CatalogItem] = [
        // Produce
        CatalogItem(name: "Tomatoes",        category: .produce,  defaultQuantityText: "4 count"),
        CatalogItem(name: "Onions",          category: .produce,  defaultQuantityText: "3 count"),
        CatalogItem(name: "Garlic",          category: .produce,  defaultQuantityText: "1 count"),
        CatalogItem(name: "Ginger",          category: .produce,  defaultQuantityText: "1 piece"),
        CatalogItem(name: "Potatoes",        category: .produce,  defaultQuantityText: "4 count"),
        CatalogItem(name: "Carrots",         category: .produce,  defaultQuantityText: "4 count"),
        CatalogItem(name: "Spinach",         category: .produce,  defaultQuantityText: "200 g"),
        CatalogItem(name: "Broccoli",        category: .produce,  defaultQuantityText: "1 piece"),
        CatalogItem(name: "Cauliflower",     category: .produce,  defaultQuantityText: "1 piece"),
        CatalogItem(name: "Capsicum",        category: .produce,  defaultQuantityText: "2 count"),
        CatalogItem(name: "Zucchini",        category: .produce,  defaultQuantityText: "2 count"),
        CatalogItem(name: "Cucumber",        category: .produce,  defaultQuantityText: "1 count"),
        CatalogItem(name: "Lettuce",         category: .produce,  defaultQuantityText: "1 count"),
        CatalogItem(name: "Cabbage",         category: .produce,  defaultQuantityText: "1 count"),
        CatalogItem(name: "Celery",          category: .produce,  defaultQuantityText: "1 piece"),
        CatalogItem(name: "Mushrooms",       category: .produce,  defaultQuantityText: "200 g"),
        CatalogItem(name: "Eggplant",        category: .produce,  defaultQuantityText: "1 count"),
        CatalogItem(name: "Sweet Potato",    category: .produce,  defaultQuantityText: "2 count"),
        CatalogItem(name: "Corn",            category: .produce,  defaultQuantityText: "2 count"),
        CatalogItem(name: "Peas",            category: .produce,  defaultQuantityText: "200 g"),
        CatalogItem(name: "Green Beans",     category: .produce,  defaultQuantityText: "200 g"),
        CatalogItem(name: "Asparagus",       category: .produce,  defaultQuantityText: "200 g"),
        CatalogItem(name: "Leek",            category: .produce,  defaultQuantityText: "2 count"),
        CatalogItem(name: "Spring Onions",   category: .produce,  defaultQuantityText: "1 pack"),
        CatalogItem(name: "Coriander",       category: .produce,  defaultQuantityText: "1 pack"),
        CatalogItem(name: "Parsley",         category: .produce,  defaultQuantityText: "1 pack"),
        CatalogItem(name: "Mint",            category: .produce,  defaultQuantityText: "1 pack"),
        CatalogItem(name: "Basil",           category: .produce,  defaultQuantityText: "1 pack"),
        CatalogItem(name: "Chilli",          category: .produce,  defaultQuantityText: "4 count"),
        CatalogItem(name: "Lemon",           category: .produce,  defaultQuantityText: "2 count"),
        CatalogItem(name: "Lime",            category: .produce,  defaultQuantityText: "2 count"),
        CatalogItem(name: "Banana",          category: .produce,  defaultQuantityText: "4 count"),
        CatalogItem(name: "Apple",           category: .produce,  defaultQuantityText: "3 count"),
        CatalogItem(name: "Orange",          category: .produce,  defaultQuantityText: "3 count"),
        CatalogItem(name: "Mango",           category: .produce,  defaultQuantityText: "2 count"),
        CatalogItem(name: "Avocado",         category: .produce,  defaultQuantityText: "2 count"),
        CatalogItem(name: "Grapes",          category: .produce,  defaultQuantityText: "300 g"),
        CatalogItem(name: "Strawberries",    category: .produce,  defaultQuantityText: "250 g"),
        CatalogItem(name: "Blueberries",     category: .produce,  defaultQuantityText: "200 g"),
        CatalogItem(name: "Pineapple",       category: .produce,  defaultQuantityText: "1 count"),

        // Dairy
        CatalogItem(name: "Milk",            category: .dairy,    defaultQuantityText: "1 l"),
        CatalogItem(name: "Eggs",            category: .dairy,    defaultQuantityText: "12 count"),
        CatalogItem(name: "Butter",          category: .dairy,    defaultQuantityText: "250 g"),
        CatalogItem(name: "Cheddar Cheese",  category: .dairy,    defaultQuantityText: "200 g"),
        CatalogItem(name: "Mozzarella",      category: .dairy,    defaultQuantityText: "200 g"),
        CatalogItem(name: "Parmesan",        category: .dairy,    defaultQuantityText: "100 g"),
        CatalogItem(name: "Yoghurt",         category: .dairy,    defaultQuantityText: "500 g"),
        CatalogItem(name: "Cream",           category: .dairy,    defaultQuantityText: "200 ml"),
        CatalogItem(name: "Sour Cream",      category: .dairy,    defaultQuantityText: "200 g"),
        CatalogItem(name: "Cream Cheese",    category: .dairy,    defaultQuantityText: "250 g"),
        CatalogItem(name: "Feta Cheese",     category: .dairy,    defaultQuantityText: "200 g"),
        CatalogItem(name: "Oat Milk",        category: .dairy,    defaultQuantityText: "1 l"),
        CatalogItem(name: "Almond Milk",     category: .dairy,    defaultQuantityText: "1 l"),

        // Protein
        CatalogItem(name: "Chicken Breast",  category: .protein,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Chicken Thighs",  category: .protein,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Ground Beef",     category: .protein,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Beef Steak",      category: .protein,  defaultQuantityText: "300 g"),
        CatalogItem(name: "Lamb",            category: .protein,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Pork Chops",      category: .protein,  defaultQuantityText: "400 g"),
        CatalogItem(name: "Bacon",           category: .protein,  defaultQuantityText: "200 g"),
        CatalogItem(name: "Salmon",          category: .protein,  defaultQuantityText: "400 g"),
        CatalogItem(name: "Tuna",            category: .protein,  defaultQuantityText: "400 g"),
        CatalogItem(name: "Prawns",          category: .protein,  defaultQuantityText: "300 g"),
        CatalogItem(name: "Tofu",            category: .protein,  defaultQuantityText: "400 g"),
        CatalogItem(name: "Tempeh",          category: .protein,  defaultQuantityText: "300 g"),
        CatalogItem(name: "Lentils",         category: .protein,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Chickpeas",       category: .protein,  defaultQuantityText: "400 g"),
        CatalogItem(name: "Black Beans",     category: .protein,  defaultQuantityText: "400 g"),
        CatalogItem(name: "Kidney Beans",    category: .protein,  defaultQuantityText: "400 g"),
        CatalogItem(name: "Edamame",         category: .protein,  defaultQuantityText: "200 g"),

        // Grains
        CatalogItem(name: "Rice",            category: .grains,   defaultQuantityText: "1 kg"),
        CatalogItem(name: "Pasta",           category: .grains,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Spaghetti",       category: .grains,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Noodles",         category: .grains,   defaultQuantityText: "400 g"),
        CatalogItem(name: "Oats",            category: .grains,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Quinoa",          category: .grains,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Couscous",        category: .grains,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Plain Flour",     category: .grains,   defaultQuantityText: "1 kg"),
        CatalogItem(name: "Self Raising Flour", category: .grains, defaultQuantityText: "1 kg"),
        CatalogItem(name: "Breadcrumbs",     category: .grains,   defaultQuantityText: "200 g"),
        CatalogItem(name: "Cornstarch",      category: .grains,   defaultQuantityText: "200 g"),
        CatalogItem(name: "Polenta",         category: .grains,   defaultQuantityText: "500 g"),

        // Bakery
        CatalogItem(name: "Bread",           category: .bakery,   defaultQuantityText: "1 loaf"),
        CatalogItem(name: "Sourdough",       category: .bakery,   defaultQuantityText: "1 loaf"),
        CatalogItem(name: "Pita Bread",      category: .bakery,   defaultQuantityText: "1 pack"),
        CatalogItem(name: "Tortillas",       category: .bakery,   defaultQuantityText: "1 pack"),
        CatalogItem(name: "Burger Buns",     category: .bakery,   defaultQuantityText: "4 count"),
        CatalogItem(name: "Croissants",      category: .bakery,   defaultQuantityText: "4 count"),
        CatalogItem(name: "Naan",            category: .bakery,   defaultQuantityText: "4 count"),
        CatalogItem(name: "Roti",            category: .bakery,   defaultQuantityText: "6 count"),

        // Pantry staples
        CatalogItem(name: "Olive Oil",       category: .pantry,   defaultQuantityText: "500 ml"),
        CatalogItem(name: "Vegetable Oil",   category: .pantry,   defaultQuantityText: "500 ml"),
        CatalogItem(name: "Coconut Oil",     category: .pantry,   defaultQuantityText: "300 ml"),
        CatalogItem(name: "Sesame Oil",      category: .pantry,   defaultQuantityText: "250 ml"),
        CatalogItem(name: "White Vinegar",   category: .pantry,   defaultQuantityText: "500 ml"),
        CatalogItem(name: "Apple Cider Vinegar", category: .pantry, defaultQuantityText: "500 ml"),
        CatalogItem(name: "Soy Sauce",       category: .pantry,   defaultQuantityText: "250 ml"),
        CatalogItem(name: "Fish Sauce",      category: .pantry,   defaultQuantityText: "200 ml"),
        CatalogItem(name: "Oyster Sauce",    category: .pantry,   defaultQuantityText: "250 ml"),
        CatalogItem(name: "Tomato Paste",    category: .pantry,   defaultQuantityText: "140 g"),
        CatalogItem(name: "Tomato Sauce",    category: .pantry,   defaultQuantityText: "500 ml"),
        CatalogItem(name: "Coconut Milk",    category: .pantry,   defaultQuantityText: "400 ml"),
        CatalogItem(name: "Coconut Cream",   category: .pantry,   defaultQuantityText: "270 ml"),
        CatalogItem(name: "Stock Cubes",     category: .pantry,   defaultQuantityText: "1 pack"),
        CatalogItem(name: "Chicken Stock",   category: .pantry,   defaultQuantityText: "1 l"),
        CatalogItem(name: "Vegetable Stock", category: .pantry,   defaultQuantityText: "1 l"),
        CatalogItem(name: "Honey",           category: .pantry,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Sugar",           category: .pantry,   defaultQuantityText: "1 kg"),
        CatalogItem(name: "Brown Sugar",     category: .pantry,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Maple Syrup",     category: .pantry,   defaultQuantityText: "250 ml"),
        CatalogItem(name: "Peanut Butter",   category: .pantry,   defaultQuantityText: "375 g"),
        CatalogItem(name: "Tahini",          category: .pantry,   defaultQuantityText: "250 g"),
        CatalogItem(name: "Diced Tomatoes",  category: .canned,   defaultQuantityText: "400 g"),
        CatalogItem(name: "Baking Powder",   category: .pantry,   defaultQuantityText: "100 g"),
        CatalogItem(name: "Baking Soda",     category: .pantry,   defaultQuantityText: "200 g"),
        CatalogItem(name: "Vanilla Extract", category: .pantry,   defaultQuantityText: "100 ml"),

        // Indian pantry staples
        CatalogItem(name: "Moong Dal",       category: .protein,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Masoor Dal",      category: .protein,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Chana Dal",       category: .protein,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Toor Dal",        category: .protein,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Urad Dal",        category: .protein,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Rajma",           category: .protein,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Chole",           category: .protein,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Basmati Rice",    category: .grains,   defaultQuantityText: "1 kg"),
        CatalogItem(name: "Atta",            category: .grains,   defaultQuantityText: "1 kg"),
        CatalogItem(name: "Besan",           category: .grains,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Rava",            category: .grains,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Poha",            category: .grains,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Vermicelli",      category: .grains,   defaultQuantityText: "200 g"),
        CatalogItem(name: "Ghee",            category: .dairy,    defaultQuantityText: "500 g"),
        CatalogItem(name: "Paneer",          category: .dairy,    defaultQuantityText: "200 g"),
        CatalogItem(name: "Buttermilk",      category: .dairy,    defaultQuantityText: "500 ml"),
        CatalogItem(name: "Tamarind",        category: .pantry,   defaultQuantityText: "100 g"),
        CatalogItem(name: "Jaggery",         category: .pantry,   defaultQuantityText: "250 g"),
        CatalogItem(name: "Curry Leaves",    category: .produce,  defaultQuantityText: "1 pack"),
        CatalogItem(name: "Methi Leaves",    category: .produce,  defaultQuantityText: "1 pack"),
        CatalogItem(name: "Drumstick",       category: .produce,  defaultQuantityText: "4 count"),
        CatalogItem(name: "Bitter Gourd",    category: .produce,  defaultQuantityText: "2 count"),
        CatalogItem(name: "Ridge Gourd",     category: .produce,  defaultQuantityText: "2 count"),
        CatalogItem(name: "Bottle Gourd",    category: .produce,  defaultQuantityText: "1 count"),
        CatalogItem(name: "Okra",            category: .produce,  defaultQuantityText: "250 g"),
        CatalogItem(name: "Raw Banana",      category: .produce,  defaultQuantityText: "2 count"),
        CatalogItem(name: "Coconut",         category: .produce,  defaultQuantityText: "1 count"),
        CatalogItem(name: "Hing",            category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Amchur",          category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Kasuri Methi",    category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Chaat Masala",    category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Biryani Masala",  category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Pav Bhaji Masala", category: .spices,  defaultQuantityText: "50 g"),
        CatalogItem(name: "Sambhar Masala",  category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Rasam Powder",    category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Dry Red Chilli",  category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Kashmiri Chilli", category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Mango Pickle",    category: .pantry,   defaultQuantityText: "300 g"),
        CatalogItem(name: "Coconut Chutney", category: .pantry,   defaultQuantityText: "200 g"),

        // Spices
        CatalogItem(name: "Salt",            category: .spices,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Black Pepper",    category: .spices,   defaultQuantityText: "100 g"),
        CatalogItem(name: "Turmeric",        category: .spices,   defaultQuantityText: "100 g"),
        CatalogItem(name: "Cumin",           category: .spices,   defaultQuantityText: "100 g"),
        CatalogItem(name: "Coriander Powder", category: .spices,  defaultQuantityText: "100 g"),
        CatalogItem(name: "Chilli Powder",   category: .spices,   defaultQuantityText: "100 g"),
        CatalogItem(name: "Paprika",         category: .spices,   defaultQuantityText: "100 g"),
        CatalogItem(name: "Garam Masala",    category: .spices,   defaultQuantityText: "100 g"),
        CatalogItem(name: "Curry Powder",    category: .spices,   defaultQuantityText: "100 g"),
        CatalogItem(name: "Cinnamon",        category: .spices,   defaultQuantityText: "100 g"),
        CatalogItem(name: "Cardamom",        category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Cloves",          category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Bay Leaves",      category: .spices,   defaultQuantityText: "1 pack"),
        CatalogItem(name: "Oregano",         category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Thyme",           category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Rosemary",        category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Mixed Herbs",     category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Chilli Flakes",   category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Mustard Seeds",   category: .spices,   defaultQuantityText: "100 g"),
        CatalogItem(name: "Fennel Seeds",    category: .spices,   defaultQuantityText: "50 g"),
        CatalogItem(name: "Star Anise",      category: .spices,   defaultQuantityText: "1 pack"),
        CatalogItem(name: "Nutmeg",          category: .spices,   defaultQuantityText: "50 g"),

        // Canned / preserved
        CatalogItem(name: "Canned Chickpeas", category: .canned,  defaultQuantityText: "400 g"),
        CatalogItem(name: "Canned Lentils",  category: .canned,   defaultQuantityText: "400 g"),
        CatalogItem(name: "Canned Corn",     category: .canned,   defaultQuantityText: "400 g"),
        CatalogItem(name: "Canned Tuna",     category: .canned,   defaultQuantityText: "185 g"),
        CatalogItem(name: "Canned Salmon",   category: .canned,   defaultQuantityText: "415 g"),
        CatalogItem(name: "Canned Beans",    category: .canned,   defaultQuantityText: "400 g"),
        CatalogItem(name: "Canned Pineapple", category: .canned,  defaultQuantityText: "440 g"),
        CatalogItem(name: "Passata",         category: .canned,   defaultQuantityText: "700 ml"),
        CatalogItem(name: "Olives",          category: .canned,   defaultQuantityText: "280 g"),
        CatalogItem(name: "Sun-dried Tomatoes", category: .canned, defaultQuantityText: "200 g"),

        // Frozen
        CatalogItem(name: "Frozen Peas",     category: .frozen,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Frozen Corn",     category: .frozen,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Frozen Edamame",  category: .frozen,   defaultQuantityText: "400 g"),
        CatalogItem(name: "Frozen Spinach",  category: .frozen,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Frozen Mixed Veg", category: .frozen,  defaultQuantityText: "500 g"),
        CatalogItem(name: "Frozen Prawns",   category: .frozen,   defaultQuantityText: "400 g"),
        CatalogItem(name: "Frozen Fish",     category: .frozen,   defaultQuantityText: "400 g"),
        CatalogItem(name: "Frozen Berries",  category: .frozen,   defaultQuantityText: "400 g"),
        CatalogItem(name: "Ice Cream",       category: .frozen,   defaultQuantityText: "1 l"),

        // Beverages
        CatalogItem(name: "Water",           category: .beverages, defaultQuantityText: "2 l"),
        CatalogItem(name: "Orange Juice",    category: .beverages, defaultQuantityText: "1 l"),
        CatalogItem(name: "Coffee",          category: .beverages, defaultQuantityText: "250 g"),
        CatalogItem(name: "Tea",             category: .beverages, defaultQuantityText: "1 pack"),
        CatalogItem(name: "Green Tea",       category: .beverages, defaultQuantityText: "1 pack"),
        CatalogItem(name: "Sparkling Water", category: .beverages, defaultQuantityText: "1 l"),

        // Snacks
        CatalogItem(name: "Almonds",         category: .snacks,   defaultQuantityText: "200 g"),
        CatalogItem(name: "Cashews",         category: .snacks,   defaultQuantityText: "200 g"),
        CatalogItem(name: "Walnuts",         category: .snacks,   defaultQuantityText: "200 g"),
        CatalogItem(name: "Peanuts",         category: .snacks,   defaultQuantityText: "300 g"),
        CatalogItem(name: "Mixed Nuts",      category: .snacks,   defaultQuantityText: "300 g"),
        CatalogItem(name: "Dark Chocolate",  category: .snacks,   defaultQuantityText: "200 g"),
        CatalogItem(name: "Crackers",        category: .snacks,   defaultQuantityText: "1 pack"),
        CatalogItem(name: "Rice Cakes",      category: .snacks,   defaultQuantityText: "1 pack"),
        CatalogItem(name: "Popcorn",         category: .snacks,   defaultQuantityText: "1 pack"),
        CatalogItem(name: "Chips",           category: .snacks,   defaultQuantityText: "1 pack"),
        CatalogItem(name: "Granola",         category: .snacks,   defaultQuantityText: "500 g"),
        CatalogItem(name: "Protein Bar",     category: .snacks,   defaultQuantityText: "4 count"),
    ]

    static func items(matching query: String) -> [CatalogItem] {
        let normalized = KnownInventoryItemNormalizer.normalize(query)
        guard !normalized.isEmpty else { return all }
        return all.filter {
            KnownInventoryItemNormalizer.normalize($0.name).contains(normalized)
                || $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    static func items(in category: InventoryCategory) -> [CatalogItem] {
        all.filter { $0.category == category }
    }
}
