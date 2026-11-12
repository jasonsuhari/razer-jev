extension WatchMode {
    static let catsAndDogs = WatchMode(
        id: "catdog",
        title: "Cat → red, dog → green",
        scope: .aroundPointer(points: 320),
        question: "`screen` is part of a computer screen. The mouse pointer is at the centre of the magenta ring. What is the pointer resting on?",
        answers: [
            Answer(id: "cat", meaning: "A cat or kitten, in a photo, video or drawing.", light: .red),
            Answer(id: "dog", meaning: "A dog or puppy, in a photo, video or drawing.", light: .green),
            Answer(id: "neither", meaning: "Anything that is not a cat or a dog: text, a button, background, empty space, a person, another animal or object.", light: .off),
        ])
}
