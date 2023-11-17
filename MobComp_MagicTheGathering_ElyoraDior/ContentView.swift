import SwiftUI

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

class CollectionStore: ObservableObject {
    @Published var collectionCards: [MTGCard] = [] {
        didSet {
            print("Collection updated: \(collectionCards)")
        }
    }
    
    var showAlert = false
    var alertMessage = ""
    
    func addToCollection(card: MTGCard) {
        // Check if the card already exists in the collection
        if !collectionCards.contains(where: { $0.id == card.id }) {
            collectionCards.append(card)
        } else {
            showAlert = true
            alertMessage = "Card \(card.name) is already in the collection"
        }
    }
}


struct SearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            TextField("Search", text: $searchText)
                .padding(15)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .frame(maxWidth: .infinity)
            Button(action: {
                searchText = ""
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 8)
            .opacity(searchText.isEmpty ? 0 : 1)
        }
        .padding()
    }
}

struct MTGCardView: View {
    var card: MTGCard
    @State private var showVersions = true
    @State private var showRulings = false
    @State private var isPopUpVisible = false
    @State private var scrollOffset: CGFloat = 0
    @Binding var selectedCardIndex: Int
    var mtgCards: [MTGCard]
    
    @ObservedObject var collectionStore: CollectionStore
    @State private var showDuplicateCardAlert = false
    
    @State private var showAddToDeckAlert = false
    @Binding var decks: [Deck]
    @State private var selectedDeck: Deck?
    @State private var isDeckUnderDevelopmentAlert = false
    
    @State private var isActionSheetPresented = false
    @State private var actionSheetToShow: ActionSheet?

    @State private var selectedCard: MTGCard? = nil {
        didSet {
            // This block will be executed whenever selectedCardIndex changes
            // You can perform actions here based on the selectedCard
            // For example, print the selected card's name:
            if let cardName = selectedCard?.name {
                print("Selected Card Name: \(cardName)")
            }
        }
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        // Tampilkan gambar kartu
                        Button(action: {
                            isPopUpVisible.toggle()
                        }) {
                            AsyncImage(url: URL(string: selectedCard?.image_uris?.art_crop ?? "")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .onAppear {
                                            updateSelectedCard()
                                        }
                                case .failure:
                                    Image(systemName: "exclamationmark.triangle")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.red)
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    ProgressView()
                                }
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                
                                Text(selectedCard?.name ?? "")
                                    .font(.system(size: 25, weight: .bold))
                                    .bold()
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10)
                                    
                                    .fixedSize(horizontal: false, vertical: true) // Allow compression with ellipsis
                                
                                Spacer()
                                
                                if let manaCost = selectedCard?.mana_cost {
                                    displayManaCost(manaCost: manaCost)
                                        .padding(.leading, 10)
                                        .padding(.horizontal, 10)// Adjust the spacing between card name and mana cost
                                }
                            }
                            
                            
                            Text(selectedCard?.type_line ?? "")
                                .bold()
                                .font(.title3)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 10)
                            
                            Text(selectedCard?.oracle_text ?? "")
                                .padding(10)
                                .padding(.horizontal, 8)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 2, y: 2) // Soft shadow at the bottom
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 2, y: 0) // Soft shadow on the right side
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            
                            
                        }
                        
                        
                        HStack{
                            // Left Arrow Button
                            Button(action: {
                                withAnimation {
                                    if selectedCardIndex > 0 {
                                        selectedCardIndex -= 1
                                        print("Selected Index Decremented: \(selectedCardIndex)")
                                    }
                                }
                            }) {
                                Image(systemName: "arrow.left.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 30))
                                    .frame(width: 40)
                                
                            }
                            
                            
                            // Versions Button
                            Button(action: {
                                showVersions = true
                                showRulings = false
                            }) {
                                Text("Versions")
                                    .padding()
                                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                                    .background(showVersions ? Color.red : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(25)
                            }
                            
                            // Rulings Button
                            Button(action: {
                                showVersions = false
                                showRulings.toggle()
                            }) {
                                Text("Rulings")
                                    .padding()
                                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                                    .background(showRulings ? Color.red : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(25)
                            }
                            .disabled(showRulings)
                            
                            // Right Arrow Button
                            Button(action: {
                                
                                if selectedCardIndex < mtgCards.count - 1 {
                                    selectedCardIndex += 1
                                    print("Selected Index Incremented: \(selectedCardIndex)")
                                }
                            }) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 30))
                                    .frame(width: 40)
                            }
                        }
                        .padding(10)
                        
                        // Versions Information
                        if let selectedCard = selectedCard, showVersions {
                            VersionsView(selectedCard: selectedCard)
                        }
                        
                        // Rulings Information
                        if let selectedCard = selectedCard, showRulings {
                            RulingsView(selectedCard: selectedCard)
                        }
                        VStack{
                            Button("Add to Collection") {
                                if let selectedCard = selectedCard {
                                    DispatchQueue.main.async {
                                        collectionStore.addToCollection(card: selectedCard)
                                        collectionStore.objectWillChange.send() // Ensure UI refresh
                                    }
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(25)
      
                            Button("Add to Deck") {
                                if decks.isEmpty {
                                    showAddToDeckAlert = true
                                } else {
                                    isDeckUnderDevelopmentAlert = true
                                }
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            
                            
                            
                        }
                        .alert(isPresented: $isDeckUnderDevelopmentAlert) {
                            Alert(
                                title: Text("Deck Functionality"),
                                message: Text("The deck functionality is still under development."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                        .alert(isPresented: $showAddToDeckAlert) {
                                    Alert(
                                        title: Text("No Decks Available"),
                                        message: Text("Please create a deck first in the Decks tab."),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }
                        
                        
                    }
                }
                .opacity(isPopUpVisible ? 0.5 : 1.0)
                
                }
            .gesture(DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        if selectedCardIndex < mtgCards.count - 1 {
                            withAnimation {
                                selectedCardIndex += 1
                            }
                        }
                    } else if value.translation.width > 50 {
                        if selectedCardIndex > 0 {
                            withAnimation {
                                selectedCardIndex -= 1
                            }
                        }
                    }
                }
            )
            

            // Semi-transparent background for the pop-up
            if isPopUpVisible {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isPopUpVisible = false
                        }
                    }
            }

            // Pop-up card
            if isPopUpVisible {
                VStack {
                    // Display the original card image here
                    AsyncImage(url: URL(string: selectedCard?.image_uris?.large ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(15)
                                .padding()
                        case .failure:
                            Image(systemName: "exclamationmark.triangle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.red)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            ProgressView()
                        }
                    }
                    .padding()
                }
                .transition(.opacity)

            }
        }
        .onAppear {
            // Initial setup when the view appears
            updateSelectedCard()
        }
        .onChange(of: selectedCardIndex) { newIndex in
                    // Respond to changes in selectedCardIndex
                    updateSelectedCard()
                }
    }
    
    var deckButtons: [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        for deck in decks {
            let button = ActionSheet.Button.default(
                Text(deck.name)
            ) {
                selectedDeck = deck
                // Add logic to add the card to the selected deck
                // This could involve calling a function/method to add the card to the selected deck
            }
            buttons.append(button)
        }

        let cancelButton = ActionSheet.Button.cancel {
            isActionSheetPresented = false
        }
        buttons.append(cancelButton)

        return buttons
    }
    
    

    private func updateSelectedCard() {
        if let newCard = mtgCards[safe: selectedCardIndex] {
            selectedCard = newCard
            showVersions = true
            showRulings = false
        }
    

    }
    
    let manaSymbols: [Character: String] = [
        "1": "mana1",
        "2": "mana2",
        "3": "mana3",
        "4": "mana4",
        "7": "mana7",
        "W": "manawhite",
        "U": "manablue",
        "G": "manatree",
        "B": "manaskull",
        "R": "manafire",

    ]
    
    
    // Function to add the card to the selected deck
    func addCardToDeck(card: MTGCard, deck: inout Deck) {
        // Assuming 'cards' is an array of cards in each deck
        // Assuming 'decks' is an array of Deck objects

        // Check if the card already exists in the selected deck
        if !deck.cards.contains(where: { $0.id == card.id }) {
            // If not, add the card to the deck
            deck.cards.append(card)
        } else {
            // Handle the scenario where the card already exists in the deck
            // For example, show an alert
            // You can modify this based on your UI/UX requirements
            print("Card \(card.name) is already in \(deck.name)")
        }
    }

    // When a deck is chosen from the action sheet



    
    private func displayManaCost(manaCost: String) -> some View {
        HStack(spacing: 5) {
            Spacer()
            ForEach(Array(manaCost), id: \.self) { symbol in
                if symbol == "{" || symbol == "}" {
                    EmptyView() // Exclude curly braces from display
                } else if symbol == "/" {
                    Text(String(symbol))
                        .foregroundColor(.black) // Handle dual-color mana symbols or other special cases
                } else if let imageName = manaSymbols[symbol] {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        // Add any additional styling or modifiers here
                } else {
                    Text(String(symbol))
                        .foregroundColor(.black) // For symbols not found in mappings
                        .fontWeight(.bold)
                }
            }
        }
    }
}




struct VersionsView: View {
    var selectedCard: MTGCard

    var body: some View {
        VStack {
            // Display version-related information here, such as prices and types
            Text("Versions for \(selectedCard.name)")
                .font(.title)

            // Add a section to display prices
            PricesSectionView(prices: selectedCard.prices)
        }
        .padding()
    }
}

struct PricesSectionView: View {
    var prices: MTGCard.Prices?

    var body: some View {
        // Check if prices exist
        if let prices = prices {
            Section(header: Text("Prices")) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), alignment: .leading),
                    GridItem(.flexible(), alignment: .leading),
                    GridItem(.flexible(), alignment: .leading)
                ], spacing: 16) {
                    PriceItemView(title: "USD", value: prices.usd)
                    PriceItemView(title: "USD Foil", value: prices.usd_foil)
                    PriceItemView(title: "USD Etched", value: prices.usd_etched)
                    PriceItemView(title: "Euro", value: prices.eur)
                    PriceItemView(title: "Euro Foil", value: prices.eur_foil)
                    PriceItemView(title: "Tix", value: prices.tix)
                }
                .padding(.vertical, 8)
            }
        } else {
            Text("Prices not available")
        }
    }
}

struct PriceItemView: View {
    var title: String
    var value: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .bold()
                .foregroundColor(.secondary)
            Text(value ?? "N/A")
                .font(.body)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 60, alignment: .leading)
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}


struct RulingsView: View {
    var selectedCard: MTGCard

    var body: some View {
        VStack {
            Text("Legalities for \(selectedCard.name)")
                .font(.title)
                .padding()

            // Convert dictionary to array
            let legalitiesArray = Array(selectedCard.legalities)

            // Use LazyVGrid to split the legalities into two columns
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 5) {
                ForEach(0..<legalitiesArray.count) { index in
                    let (format, legality) = legalitiesArray[index]

                    HStack(alignment: .top) {
                        // Display "Legal" or "Not Legal" text
                        FrameView(backgroundColor: legality == "legal" ? Color.green : Color.gray) {
                            Text(legality == "legal" ? "Legal" : "Not Legal")
                                .foregroundColor(legality == "legal" ? .white : .primary) // Set font color
                                .frame(maxWidth: .infinity, alignment: .leading) // Align text to the left within the frame
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                        // Display the format
                        Text(format)
                            .foregroundColor(.primary)
                            .font(.system(size: 15.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, 7)
                }
            }
            .padding()
        }
    }
}


struct FrameView<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    
    init(backgroundColor: Color = Color.gray.opacity(0.1), @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(3)
            .background(backgroundColor)
            .cornerRadius(5)
            .frame(maxWidth: .infinity)
    }
}

struct Deck: Identifiable {
    let id = UUID()
    let name: String
    var cards: [MTGCard] = []
}


struct ContentView: View {
    @State private var mtgCards: [MTGCard] = []
    @State private var searchText = ""
    @State private var isSortedAZ = false
    @State private var selectedCardIndex = 0
    @State private var isNavigationActive = false
    @State private var sortSelection = 0
    @ObservedObject var collectionStore = CollectionStore()
    @State private var decks: [Deck] = []
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

    var body: some View {
        TabView {
            
            Text("⚠️Home⚠️\n is under development")
                .multilineTextAlignment(.center)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            
            NavigationView {
                ScrollView {
                    VStack {
                        HStack {
                            // Search Bar
                            TextField("Search", text: $searchText)
                                .padding(15)
                                .background(Color(.systemGray6))
                                .cornerRadius(30)
                                .frame(maxWidth: .infinity)

                            // Sort Button
                            Picker("Sort", selection: $sortSelection) {
                                Text("Sort A-Z").tag(0)
                                Text("Sort Z-A").tag(1)
                                Text("Sort Collector No.")
                                    .tag(2)
                                    .lineLimit(1)
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: sortSelection) { newValue in
                                switch newValue {
                                case 0:
                                    mtgCards.sort { $0.name < $1.name }
                                case 1:
                                    mtgCards.sort { $0.name > $1.name }
                                case 2:
                                    mtgCards.sort { Int($0.collector_number ?? "0") ?? 0 < Int($1.collector_number ?? "0") ?? 0 }
                                default:
                                    break
                                }
                            }
                            .padding(.trailing, 16) // Adjust spacing between search bar and sort button
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(mtgCards.indices.filter {
                                searchText.isEmpty || mtgCards[$0].name.localizedCaseInsensitiveContains(searchText)
                            }, id: \.self) { index in
                                let card = mtgCards[index]

                                CardImageView(card: card) {
                                    // Your custom onTap closure
                                    selectedCardIndex = index
                                    isNavigationActive = true
                                }
                                .frame(height: 200)
                                .background(NavigationLink("", destination: MTGCardView(card: card, selectedCardIndex: $selectedCardIndex, mtgCards: mtgCards, collectionStore: collectionStore, decks: $decks), isActive: $isNavigationActive))
                            }
                        
                        }



                        .padding()
                    }
                   
                    .onAppear {
                        if let data = loadJSON() {
                                                do {
                                                    let decoder = JSONDecoder()
                                                    let cards = try decoder.decode(MTGCardList.self, from: data)
                                                    mtgCards = cards.data.map { card in
                                                        var modifiedCard = card
                                                        modifiedCard.legalities = card.legalities
                                                        return modifiedCard
                                                    }
                                                    mtgCards.sort { $0.name < $1.name }
                                                } catch {
                                print("Error decoding JSON: \(error)")
                            }
                        }
                    }
                    .navigationBarTitle("MTG Cards")
                }
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }

            NavigationView {
                ScrollView {
                    VStack {
                        // Use ForEach to create a NavigationLink for each card in the collection
                        ForEach(collectionStore.collectionCards, id: \.id) { card in
                            NavigationLink(destination: MTGCardView(card: card, selectedCardIndex: $selectedCardIndex, mtgCards: mtgCards, collectionStore: collectionStore, decks: $decks)) {
                                HStack {
                                    // Displaying card image on the left
                                    AsyncImage(url: URL(string: card.image_uris?.small ?? "")) { phase in
                                        switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 50, height: 50)
                                                    .cornerRadius(8)
                                            case .failure:
                                                Image(systemName: "photo")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 50, height: 50)
                                                    .foregroundColor(.gray)
                                            case .empty:
                                                ProgressView()
                                            @unknown default:
                                                ProgressView()
                                        }
                                    }
                                    .padding()
                                    
                                    Text(card.name)
                                        .font(.title)
                                        .padding()
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .padding(.trailing, 20)
                                }
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 2, y: 2) // Bottom-right shadow
                                )
                                .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 5)
                        }

                    }
                }
                .navigationBarTitle("Collection")
                .padding()
            }
            .tabItem {
                Image(systemName: "square.stack.3d.up")
                Text("Collection")
            }
        
            
                .alert(isPresented: $collectionStore.showAlert) {
                    Alert(title: Text("Duplicate Card"),
                          message: Text(collectionStore.alertMessage),
                          dismissButton: .default(Text("OK")))
                }

            NavigationView {
                 ScrollView {
                     // Decks tab
                     VStack {
                         // Display decks here
                         ForEach(decks) { deck in
                             HStack {
                                 // Deck icon of stacked rectangles
                                 Image(systemName: "rectangle.stack.fill")
                                     .foregroundColor(.blue)
                                     .font(.title)

                                 // Deck name
                                 Text(deck.name)
                                     .font(.headline)
                                     .foregroundColor(.black) // Customize color if needed

                                 Spacer()

                                 
                                 Button(action: {
                                     // Handle actions related to this deck
                                 }) {
                                     Text("Open Deck")
                                         .foregroundColor(.blue)
                                 }
                             }
                             .padding()
                             .background(Color.white) // Set background color
                             .cornerRadius(8) // Adjust corner radius if required
                             .shadow(radius: 3) // Add shadow or customize as needed
                             .padding(.horizontal) // Adjust horizontal padding
                             .padding(.vertical, 5) // Adjust vertical padding
                             .padding(.bottom, 8) // Add bottom padding between decks
                         }


                         Button(action: {
                             // Create a new deck
                             let newDeckName = "Deck \(decks.count + 1)"
                             decks.append(Deck(name: newDeckName))
                         }) {
                             Text("Add Deck +")
                                 .padding()
                                 .foregroundColor(.blue)
                         }
                         .frame(maxWidth: .infinity, alignment: .trailing)
                         .padding()
                     }
                 }
                 .navigationBarTitle("Decks")
             }
                .tabItem {
                    Image(systemName: "rectangle.stack.fill")
                    Text("Decks")
                }

            Text("⚠️Scan⚠️\n is under development")
                .multilineTextAlignment(.center)
                .tabItem {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan")
                }
        }
    }

    // Function to load data from a JSON file
    func loadJSON() -> Data? {
        if let path = Bundle.main.path(forResource: "WOT-Scryfall", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                return data
            } catch {
                print("Error loading JSON: \(error)")
            }
        }
        return nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CardImageView: View {
    var card: MTGCard
    var onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            // Card image with price overlay
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: card.image_uris?.large ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                            .padding(3)
                    case .failure:
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.red)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        ProgressView()
                    }
                }
                
                if let price = card.prices?.usd {
                    Text("$\(price)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding(6)
                }
            }
            
            // Text under the image
            Text(card.name)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onTapGesture {
            onTap()
        }
    }
}
