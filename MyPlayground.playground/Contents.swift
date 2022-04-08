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
      // Without an Async call, the Observable lifecycle will run instantly, hence .shared() will never find the Observable in mid lifecycle execution
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        print("Observable new value")
        observer.onNext(10)
        observer.onCompleted()
        print("Observable sequence completed")
      }
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

// let a = Monopoly()
// a.configureBindings()

enum ErrorType: Error {
  case error1, error2
}

/// # Observable Types & Traits
func run5() {
  // Empty observable
  let emptyObservable = Observable<Void>.empty()
  emptyObservable.subscribe(onNext: { _ in
    print("Will never emit a value")
  }, onCompleted: {
    print("Will only Complete")
  })

  // Endless observable (never completes or emits a value)
  let neverObservable = Observable<Void>.never()
  neverObservable.subscribe(onNext: { _ in
    print("Never emits onNext()")
  }, onCompleted: {
    print("Never completes")
  }, onDisposed: {
    print("Never released memory")
  })

  let rangeObservable = Observable<Int>.range(start: 1, count: 10)
  let singleObservable = Single<String>.create { observer in
    observer(.success("Success owo"))
    observer(.failure(ErrorType.error1))
    return Disposables.create()
  }
  let completableObservable = Completable.create { observer in
    observer(.completed)
    observer(.error(ErrorType.error2))
    return Disposables.create()
  }
  let maybeObservable = Maybe<String>.create(subscribe: { observer in
    observer(.error(ErrorType.error1))
    observer(.success("Success owo maybe"))
    observer(.completed)
    return Disposables.create()
  })
}

// run5()

/// # Subjects
/// Work as both Observables & Observers
func run6() {
  // PublishSubject
  let subject1 = PublishSubject<String>()
  let subject2 = BehaviorSubject(value: "1")
  let subject3 = ReplaySubject<String>.create(bufferSize: 10)
}

// run6()

func run7() {
  let behaviorSubject: BehaviorSubject<String> = BehaviorSubject(value: "1")
  behaviorSubject.onNext("2")
  behaviorSubject.subscribe(onNext: { value in
    print("next value: \(value)")
  })
}

// run7()

func run8() {
  let subject = PublishSubject<String>()
  // Subject didn't catch this sequence value as it wasn't subscribed to it just yet.
  subject.onNext("Is anyone listening?")

  let subscriptionOne = subject
    .subscribe(onNext: { value in
      print("value: \(value)")
    })

  subject.on(.next("1"))
  subject.onNext("2")

  let subscriptionTwo = subject
    .subscribe { event in
      // Event contain the Emitted element from onNext events
      print("value: 2)", event.element ?? event)
    }
  subject.onNext("3")

  // Termine the subscriptionOne
  subscriptionOne.dispose()

  subject.onNext("4")

  // Stop Event, Observable Sequence completed
  subject.onCompleted()

  // Will not be emitted to its Subscribers
  subject.onNext("5")

  // Subsciption released
  subscriptionTwo.dispose()

  let disposeBag = DisposeBag()

  // subscriptionThree
  subject
    .subscribe { event in
      print("value: 3)", event.element ?? event)
    }
    .disposed(by: disposeBag)

  subject.onNext("?")

  // Will be emited as "completed" events, regardless of the value passed in, if the Sequence has already completed.
  // subject.onNext("5") -> for subscriptionTwo
  // subject.onNext("?") -> for subscriptionThree
}

// run8()

func run9() {
  let subject = BehaviorSubject(value: "1")
  let subscriber1 = subject.subscribe(onNext: { value in
    print("value: \(value)")
  })
  
  // Can only set buffer size at create()
  let replay = ReplaySubject<String>.create(bufferSize: 2)
  let a = ReplaySubject<Int>.create { observer in
    observer.onNext(1)
    return Disposables.create()
  }
}

run9()
