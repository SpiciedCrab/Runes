import SwiftCheck
import XCTest
import Runes

class ArraySpec: XCTestCase {
    func testFunctor() {
        // fmap id = id
        property("identity law") <- forAll { (xs: [String]) in
            let lhs = id <^> xs
            let rhs = xs

            return lhs == rhs
        }

        // fmap (f . g) = (fmap f) . (fmap g)
        property("function composition law") <- forAll { (a: ArrayOf<String>, fa: ArrowOf<String, String>, fb: ArrowOf<String, String>) in
            let xs = a.getArray
            let f = fa.getArrow
            let g = fb.getArrow

            let lhs = compose(f, g) <^> xs
            let rhs = compose(curry(<^>)(f), curry(<^>)(g))(xs)

            return lhs == rhs
        }
    }

    func testApplicative() {
        // pure id <*> x = x
        property("identity law") <- forAll { (xs: [String]) in
            let lhs = pure(id) <*> xs
            let rhs = xs

            return lhs == rhs
        }

        // pure f <*> pure x = pure (f x)
        property("homomorphism law") <- forAll { (x: String, fa: ArrowOf<String, String>) in
            let f = fa.getArrow

            let lhs: [String] = pure(f) <*> pure(x)
            let rhs: [String] = pure(f(x))

            return rhs == lhs
        }

        // f <*> pure x = pure ($ x) <*> f
        property("interchange law") <- forAll { (x: String, fa: ArrayOf<ArrowOf<String, String>>) in
            let f = fa.getArray.map { $0.getArrow }

            let lhs = f <*> pure(x)
            let rhs = pure({ $0(x) }) <*> f

            return lhs == rhs
        }

        // f <*> (g <*> x) = pure (.) <*> f <*> g <*> x
        property("composition law") <- forAll { (a: ArrayOf<String>, fa: ArrayOf<ArrowOf<String, String>>, fb: ArrayOf<ArrowOf<String, String>>) in
            let x = a.getArray
            let f = fa.getArray.map { $0.getArrow }
            let g = fb.getArray.map { $0.getArrow }

            let lhs = f <*> (g <*> x)
            let rhs = pure(curry(compose)) <*> f <*> g <*> x

            return lhs == rhs
        }
    }

    func testMonad() {
        // return x >>= f = f x
        property("left identity law") <- forAll { (x: String, fa: ArrowOf<String, String>) in
            let f: String -> [String] = compose(fa.getArrow, pure)

            let lhs = pure(x) >>- f
            let rhs = f(x)

            return lhs == rhs
        }

        // m >>= return = m
        property("right identity law") <- forAll { (x: [String]) in
            let lhs = x >>- pure
            let rhs = x

            return lhs == rhs
        }

        // (m >>= f) >>= g = m >>= (\x -> f x >>= g)
        property("associativity law") <- forAll { (a: ArrayOf<String>, fa: ArrowOf<String, String>, fb: ArrowOf<String, String>) in
            let m = a.getArray
            let f: String -> [String] = compose(fa.getArrow, pure)
            let g: String -> [String] = compose(fb.getArrow, pure)

            let lhs = (m >>- f) >>- g
            let rhs = m >>- { x in f(x) >>- g }

            return lhs == rhs
        }
    }
}
