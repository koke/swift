// RUN: rm -rf %t
// RUN: mkdir -p %t
//
// RUN: %target-clang -fobjc-arc %S/Inputs/ObjCClasses/ObjCClasses.m -c -o %t/ObjCClasses.o
// RUN: %target-build-swift -I %S/Inputs/ObjCClasses/ %t/ObjCClasses.o %s -o %t/a.out
// RUN: %target-run %t/a.out

// REQUIRES: executable_test
// REQUIRES: objc_interop

import Foundation
import StdlibUnittest
import ObjCClasses

var ImportedObjCGenerics = TestSuite("ImportedObjCGenerics")

ImportedObjCGenerics.test("Creation") {
  let cs = Container<NSString>(object: "i-just-met-you")
  expectEqual("i-just-met-you", cs.object)
  expectTrue(cs.dynamicType === Container<NSString>.self)
  expectTrue(cs.dynamicType === Container<AnyObject>.self)
}

ImportedObjCGenerics.test("Blocks") {
  let cs = Container<NSString>(object: "and-this-is-crazy")

  var fromBlock: NSString = ""
  cs.processObject { fromBlock = $0 }
  expectEqual("and-this-is-crazy", fromBlock)

  cs.updateObject { "but-heres-my-number" }
  expectEqual("but-heres-my-number", cs.object)
}

ImportedObjCGenerics.test("Categories") {
  let cs = Container<NSString>(cat1: "so-call-me-maybe")
  expectEqual("so-call-me-maybe", cs.getCat1())

  cs.setCat1("its-hard-to-look-right")
  expectEqual("its-hard-to-look-right", cs.cat1Property)
}

ImportedObjCGenerics.test("Subclasses") {
  let subContainer = SubContainer<NSString>(object: "at-you-baby")
  expectEqual("at-you-baby", subContainer.object)

  let nestedContainer = NestedContainer<NSString>(object: Container(object: "but-heres-my-number"))
  expectEqual("but-heres-my-number", nestedContainer.object.object)

  let stringContainer = StringContainer(object: "so-call-me-maybe")
  expectEqual("so-call-me-maybe", stringContainer.object)
}

ImportedObjCGenerics.test("SwiftGenerics") {
  func openContainer<T: AnyObject>(_ x: Container<T>) -> T {
    return x.object
  }
  func openStringContainer<T: Container<NSString>>(_ x: T) -> NSString {
    return x.object
  }
  func openArbitraryContainer<S: AnyObject, T: Container<S>>(_ x: T) -> S {
    return x.object
  }

  let scs = SubContainer<NSString>(object: "before-you-came-into-my-life")
  expectEqual("before-you-came-into-my-life", openContainer(scs))
  expectEqual("before-you-came-into-my-life", openStringContainer(scs))
  expectEqual("before-you-came-into-my-life", openArbitraryContainer(scs))

  let cs = Container<NSString>(object: "i-missed-you-so-bad")
  expectEqual("i-missed-you-so-bad", openContainer(cs))
  expectEqual("i-missed-you-so-bad", openStringContainer(cs))
  expectEqual("i-missed-you-so-bad", openArbitraryContainer(cs))

  let strContainer = SubContainer<NSString>(object: "i-missed-you-so-so-bad")
  expectEqual("i-missed-you-so-so-bad", openContainer(strContainer))
  expectEqual("i-missed-you-so-so-bad", openStringContainer(strContainer))
  expectEqual("i-missed-you-so-so-bad", openArbitraryContainer(strContainer))

  let numContainer = Container<NSNumber>(object: NSNumber(value: 21))
  expectEqual(NSNumber(value: 21), openContainer(numContainer))
  expectEqual(NSNumber(value: 21), openArbitraryContainer(numContainer))

  let subNumContainer = SubContainer<NSNumber>(object: NSNumber(value: 22))
  expectEqual(NSNumber(value: 22), openContainer(subNumContainer))
  expectEqual(NSNumber(value: 22), openArbitraryContainer(subNumContainer))
}

ImportedObjCGenerics.test("SwiftGenerics/Creation") {
  func makeContainer<T: AnyObject>(_ x: T) -> Container<T> {
    return Container(object: x)
  }

  let c = makeContainer(NSNumber(value: 22))
  expectEqual(NSNumber(value: 22), c.object)
}

ImportedObjCGenerics.test("ProtocolConstraints") {
  func copyContainerContents<T: NSCopying>(_ x: CopyingContainer<T>) -> T {
    return x.object.copy(with: nil) as! T
  }

  let cs = CopyingContainer<NSString>(object: "Happy 2012")
  expectEqual("Happy 2012", copyContainerContents(cs))
}

ImportedObjCGenerics.test("ClassConstraints") {
  func makeContainedAnimalMakeNoise<T>(_ x: AnimalContainer<T>) -> NSString {
    return x.object.noise
  }
  let petCarrier = AnimalContainer(object: Dog())
  expectEqual("woof", makeContainedAnimalMakeNoise(petCarrier))
}

class ClassWithMethodsUsingObjCGenerics: NSObject {
  func copyContainer(_ x: CopyingContainer<NSString>) -> CopyingContainer<NSString> {
    return x
  }
  func maybeCopyContainer(_ x: CopyingContainer<NSString>) -> CopyingContainer<NSString>? {
    return x
  }
}

ImportedObjCGenerics.test("ClassWithMethodsUsingObjCGenerics") {
  let x: AnyObject = ClassWithMethodsUsingObjCGenerics()
  let y = CopyingContainer<NSString>(object: "")
  let z = x.copyContainer(y)
  expectTrue(y === z)
  let w = x.perform(#selector(ClassWithMethodsUsingObjCGenerics.copyContainer), with: y).takeUnretainedValue()
  expectTrue(y === w)

  let zq = x.maybeCopyContainer(y)
  expectTrue(y === zq!)
  let wq = x.perform(#selector(ClassWithMethodsUsingObjCGenerics.maybeCopyContainer), with: y).takeUnretainedValue()
  expectTrue(y === wq)
}

ImportedObjCGenerics.test("InheritanceFromNongeneric") {
  // Test NSObject methods inherited into Container<>
  let gc = Container<NSString>(object: "")
  expectTrue(gc.description.range(of: "Container") != nil)
  expectTrue(gc.dynamicType.superclass() == NSObject.self)
  expectTrue(Container<NSString>.superclass() == NSObject.self)
  expectTrue(Container<NSObject>.superclass() == NSObject.self)
  expectTrue(Container<NSObject>.self == Container<NSString>.self)
}

public class InheritInSwift: Container<NSString> {
  public override init(object: NSString) {
    super.init(object: object.lowercased)
  }
  public override var object: NSString {
    get {
      return super.object.uppercased
    }
    set {
      super.object = newValue.lowercased
    }
  }

  public var superObject: NSString {
    get {
      return super.object
    }
  }
}

ImportedObjCGenerics.test("InheritInSwift") {
  let s = InheritInSwift(object: "HEllo")
  let sup: Container = s

  expectEqual(s.superObject, "hello")
  expectEqual(s.object, "HELLO")
  expectEqual(sup.object, "HELLO")

  s.object = "GOodbye"
  expectEqual(s.superObject, "goodbye")
  expectEqual(s.object, "GOODBYE")
  expectEqual(sup.object, "GOODBYE")

  s.processObject { o in
    expectEqual(o, "GOODBYE")
  }

  s.updateObject { "Aloha" }
  expectEqual(s.superObject, "aloha")
  expectEqual(s.object, "ALOHA")
  expectEqual(sup.object, "ALOHA")
}

runAllTests()
