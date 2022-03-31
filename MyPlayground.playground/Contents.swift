import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

import RxRelay
import RxSwift

let names = BehaviorRelay(value: ["One", "Two"])

let a = names.asObservable()
  // Filters event taht don't happen at least 1s between each other
  .throttle(.seconds(1), scheduler: MainScheduler.instance)
  .filter { names in
    names.count > 1
  }
  .map { value in
    "numbers: \(value)"
  }
//  .debug()
  .subscribe(onNext: { value in
    print(value)
  })

/// # With `throttle`, only 1 of these 3 events can happen, as there has to be an intervar of 1s, and it will wait 1 second to execute the 3rd .accept
names.accept(["Leonardo", "Estremadoyro"])
names.accept(["Leonardo2", "Estremadoyro2"])
names.accept(["Leonardo3", "Estremadoyro3"])
//names.accept(["asdf", "owo"])
//names.accept(["A", "B"])

DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
  names.accept(["X", "Z"])
}

//print("current names value: \(names.value) & type: \(type(of: names.self))")
