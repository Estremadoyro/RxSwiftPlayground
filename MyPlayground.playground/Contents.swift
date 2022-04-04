import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

import RxRelay
import RxSwift

func run1() {
  let allNames = [String]()

  let names = BehaviorRelay(value: ["One", "Two"])
  let names2 = BehaviorRelay(value: ["Three", "Four"])
  let names3 = BehaviorRelay(value: ["Anon"])

  Observable.combineLatest(names.asObservable(), names2.asObservable()) { a, b in
    // Sync filter
    a.filter { element in
      element.count > 1
    }
    print("\(a) | \(b)")
  }
  .subscribe()

  // Combines 2 Observables into 1 Observable
  Observable.combineLatest(names.asObservable(), names2.asObservable()) { name1, name2 in
    // Filter the name1 Observable value, only applies when .bind() or .subscribe()
    name1.filter { element in
      element != "jojo"
    }
    print("\(name1) | \(name2)")
  }
//  .bind(to: names3)

  // BehaviorSubject -> Represents a value that changes over time

  let a = names.asObservable()
    // Filters event taht don't happen at least 1s between each other
    .throttle(.seconds(1), scheduler: MainScheduler.instance)
    // Async filter
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
  // names.accept(["asdf", "owo"])
  // names.accept(["A", "B"])

  DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    names.accept(["X", "Z"])
  }
}

// run1()

// print("current names value: \(names.value) & type: \(type(of: names.self))")

func run2() async {
  let justObservable: Observable<String> = Observable.just("Hello")
  let ofObserfable: Observable<Int> = Observable.of(1, 2, 3, 4)
  //  Values: ..., Gets executed 4 times (1, 2, 3, 4)
  ofObserfable.subscribe(onNext: { value in
    print("Value: \(value)")
  })

  do {
    let seeValues = try await ofObserfable.asSingle().value
    print(seeValues)
  } catch {
    print("error: \(error)")
  }
}

func owo() {
  Task {
    await run2()
  }
}

// owo()

func run3() {
  // Observable sequence with only 1 element
  let justObservable: Observable<String> = Observable.just("Hello")

  // Creates an Observable with a variable number of elements
  let ofObservable: Observable<Int> = Observable.of(1, 2, 3, 4)
  let ofObservable2: Observable<[Int]> = Observable.of([1, 2, 3, 4], [11, 22, 33, 44])

  // Converts Array to a Sequence
  let fromObservable: Observable<Int> = Observable.from([1])

  ofObservable2.subscribe(onNext: { value in
    print("ofObservable2 value: \(value)")
  }, onCompleted: {
    print("Sequence completed")
  })
}

// run3()

func run4() {
  let disposeBag = DisposeBag()
  func createSourceObservable() -> Observable<Int> {
    return Observable.create { observer in
      print("Creating new observable")
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        observer.onNext(10)
        print("Observable new value")
        observer.onCompleted()
        print("Observable sequence completed")
      }
      return Disposables.create()
    }
  }

  let sourceObservable = createSourceObservable().share()

  sourceObservable.debug("A").subscribe(onNext: { value in
    print("subscriber1 new value: \(value)")
  }, onCompleted: {
    print("subscriber1 completed")
  }).disposed(by: disposeBag)

  sourceObservable.debug("B").subscribe(onNext: { value in
    print("subscriber2 new value: \(value)")
  }).disposed(by: disposeBag)
}

class ViewModel {
  func createSourceObservable() -> Observable<Int> {
    return Observable.create { observer in
      print("Creating new observable")
      print("Observable new value")
      observer.onNext(10)
      observer.onCompleted()
      print("Observable sequence completed")
      return Disposables.create()
    }
  }
}

class Monopoly {
  let viewModel = ViewModel()
  let disposeBag = DisposeBag()

  lazy var sourceObservable = viewModel.createSourceObservable().share()

  func configureBindings() {
    sourceObservable.subscribe(onNext: { value in
      print("subscriber1 new value: \(value)")
    }, onCompleted: {
      print("subscriber1 completed")
    }).disposed(by: disposeBag)

    sourceObservable.subscribe(onNext: { value in
      print("subscriber2 new value: \(value)")
    }, onCompleted: {
      print("subscriber2 completed")
    }).disposed(by: disposeBag)
  }
}

let a = Monopoly()
a.configureBindings()
