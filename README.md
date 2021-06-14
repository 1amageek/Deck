# Deck

Deck is a library that provides a UI to reproduce stacked cards for SwiftUI.


## Usage

```swift

struct Card: View {

    var data: Data

    var body: some View {
        Text("card")
    }
}

struct SimpleExample: View {

    @ObservedObject var deck: Deck = Deck((0..<100).map { Data(id: "\($0)") })

    var body: some View {
        DeckStack(deck, option: .allowed(directions: [.left, .top, .right]) ) { data, targetID in
            Card(data: data)
        }
    }
}

```

