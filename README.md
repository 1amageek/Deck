# Deck

Deck is a library that provides a UI to reproduce stacked cards for SwiftUI.



https://user-images.githubusercontent.com/11146538/123250840-7e09a680-d525-11eb-94e6-19fe96272ec6.mov




## Usage

```swift

struct Card: View {

    var data: Data

    var body: some View {
        Text(data.id)
    }
}

struct SimpleExample: View {

    @ObservedObject var deck: Deck = Deck(["😀","😃","😄","😆","😅","😂"].map { Data(id: "\($0)") })

    var body: some View {
        DeckStack(deck, option: .allowed(directions: [.left, .top, .right]) ) { data, targetID in
            Card(data: data)
        }
    }
}

```

