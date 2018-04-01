import Foundation

public extension CGFloat {
    public func degreesToRadians() -> CGFloat {
        return self * CGFloat.pi / 180
    }
}

public extension CGVector {
    public func norm() -> CGFloat {
        return sqrt(pow(self.dx, 2) + pow(self.dy, 2))
    }
}
