import SpriteKit
import AVFoundation

public class Spacecraft: SKSpriteNode {
    
    var enginePlayer: AVAudioPlayer!
    
    //Spacecraft Constants
    let mass: CGFloat = 8000//kg
    let rcsTorque: CGFloat = 20.0 //Nm
    let engineThrust: CGFloat = 16000.0 //N
    
    //Properties
    public var fuel: Int = 3500 {
        didSet {
            if fuel < 0 {
                fuel = 0
            }
        }
    } //kg
    
    public var rcsLeft: SKSpriteNode!
    public var rcsRight: SKSpriteNode!
    public var exhaustMain: SKSpriteNode!
    public var exhaustLeft: SKSpriteNode!
    public var exhaustRight: SKSpriteNode!
    
    var leftRCSWantSound = false
    var rightRCSWantsSound = false
    var engineWantsSound = false
    
    //MARK: SKSpriteNode functions
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //Perform additional Setup
        self.setup()
    }
    
    public init() {
        let texture = SKTexture(imageNamed: "SC.png")
        super.init(texture: texture, color: NSColor.clear, size: texture.size())
    }
    
    //MARK: Custom functions
    
    func setup() {
        //Load all child nodes
        guard let rcsLeft = self.childNode(withName: "RCSLeft") as? SKSpriteNode,
            let rcsRight = self.childNode(withName: "RCSRight") as? SKSpriteNode,
            let exhaustMain = self.childNode(withName: "ExhaustMain") as? SKSpriteNode,
            let exhaustLeft = self.childNode(withName: "ExhaustLeft") as? SKSpriteNode,
            let exhaustRight = self.childNode(withName: "ExhaustRight") as? SKSpriteNode else {
                
                print("Error: Couldn't load Spacecraft Child nodes!")
                return
        }
        
        //Hide exhausts on start
        rcsLeft.run(SKAction.scaleY(to: 0, duration: 0))
        rcsRight.run(SKAction.scaleY(to: 0, duration: 0))
        exhaustMain.run(SKAction.scaleY(to: 0, duration: 0))
        exhaustLeft.run(SKAction.scaleY(to: 0, duration: 0))
        exhaustRight.run(SKAction.scaleY(to: 0, duration: 0))
        
        
        //Assign Instance Properties
        self.rcsLeft = rcsLeft
        self.rcsRight = rcsRight
        self.exhaustMain = exhaustMain
        self.exhaustLeft = exhaustLeft
        self.exhaustRight = exhaustRight
        
        //Setup Audio Player
//        let data = Bundle.main.pat
//        self.enginePlayer = AVAudioPlayer(data: data)
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "engine", ofType: "wav")!)),
                let player = try? AVAudioPlayer(data: data) else {
                    print("Error: failes to create player")
            return
        }
        
        player.numberOfLoops = -1
        player.prepareToPlay()
        
        self.enginePlayer = player
        
    }
    
    //MARK: Physics
    
    public func thrust() {
        let angle = self.zRotation + CGFloat.pi / 2 //We want to thrust upwards (relative to spacecraft)
        let thrustX = cos(angle) * self.engineThrust
        let thrustY = sin(angle) * self.engineThrust
        
        self.physicsBody?.applyImpulse(CGVector(dx: thrustX, dy: thrustY))
        
        self.fuel -= 5
    }
    
    public func applyTorqueCounterClockwise() {
        self.run(SKAction.applyAngularImpulse(75, duration: 1))
        self.fuel -= 2
    }
    
    public func applyTorqueClockwise() {
        self.run(SKAction.applyTorque(-75, duration: 1))
        self.fuel -= 2
    }
    
    //MARK: Animation
    
    public func startLeftRCSAnimation() {
        let boost = SKAction.scaleY(to: 0.4, duration: 0.1)
        
        let wiggleIn = SKAction.scaleY(to: 0.22, duration: 0.1)
        let wiggleOut = SKAction.scaleY(to: 0.17, duration: 0.1)
        let wiggle = SKAction.sequence([wiggleIn, wiggleOut])
        rcsLeft.run(SKAction.sequence([boost, SKAction.repeatForever(wiggle)]), withKey: "rcs")
        
        if !exhaustLeft.hasActions() {
            let wiggleSideIn = SKAction.scaleY(to: 0.3, duration: 0.1)
            let wiggleSideOut = SKAction.scaleY(to: 0.22, duration: 0.1)
            let wiggleSide = SKAction.sequence([wiggleSideIn, wiggleSideOut])
            exhaustLeft.run(SKAction.repeatForever(wiggleSide), withKey: "rcs")
        }
        
        leftRCSWantSound = true
        enginePlayer.play()
    }
    
    public func stopLeftRCSAnimation() {
        rcsLeft.removeAction(forKey: "rcs")
        
        let shutdown = SKAction.scaleY(to: 0, duration: 0.1)
        rcsLeft.run(shutdown)
        
        if let _ = exhaustLeft.action(forKey: "rcs") {
            exhaustLeft.removeAction(forKey: "rcs")
            exhaustLeft.run(shutdown)
        }
        
        leftRCSWantSound = false
        stopAudio()
    }
    
    public func startRightRCSAnimation() {
        let boost = SKAction.scaleY(to: 0.4, duration: 0.1)
        
        let wiggleIn = SKAction.scaleY(to: 0.22, duration: 0.1)
        let wiggleOut = SKAction.scaleY(to: 0.17, duration: 0.1)
        let wiggle = SKAction.sequence([wiggleIn, wiggleOut])
        rcsRight.run(SKAction.sequence([boost, SKAction.repeatForever(wiggle)]), withKey: "rcs")
        
        if !exhaustRight.hasActions() {
            let wiggleSideIn = SKAction.scaleY(to: 0.3, duration: 0.1)
            let wiggleSideOut = SKAction.scaleY(to: 0.22, duration: 0.1)
            let wiggleSide = SKAction.sequence([wiggleSideIn, wiggleSideOut])
            exhaustRight.run(SKAction.repeatForever(wiggleSide), withKey: "rcs")
        }
        
        rightRCSWantsSound = true
        enginePlayer.play()
    }
    
    public func stopRightRCSAnimation() {
        rcsRight.removeAction(forKey: "rcs")
        
        let shutdown = SKAction.scaleY(to: 0, duration: 0.1)
        rcsRight.run(shutdown)
        
        if let _ = exhaustRight.action(forKey: "rcs") {
            exhaustRight.removeAction(forKey: "rcs")
            exhaustRight.run(shutdown)
        }
        rightRCSWantsSound = false
        stopAudio()
    }
    
    public func startThrustAnimation() {
        let boost = SKAction.scaleY(to: 1.2, duration: 0.1)
        
        let wiggleIn = SKAction.scaleY(to: 1.0, duration: 0.1)
        let wiggleOut = SKAction.scaleY(to: 0.9, duration: 0.1)
        let wiggle = SKAction.sequence([wiggleIn, wiggleOut])
        exhaustMain.run(SKAction.sequence([boost, SKAction.repeatForever(wiggle)]), withKey: "thrust")
        
        let boostSide = SKAction.scaleY(to: 0.8, duration: 0.1)
        let wiggleSideIn = SKAction.scaleY(to: 0.365, duration: 0.1)
        let wiggleSideOut = SKAction.scaleY(to: 0.34, duration: 0.1)
        let wiggleSide = SKAction.sequence([wiggleSideIn, wiggleSideOut])
        
        exhaustLeft.run(SKAction.sequence([boostSide, SKAction.repeatForever(wiggleSide)]), withKey: "thrust")
        exhaustRight.run(SKAction.sequence([boostSide, SKAction.repeatForever(wiggleSide)]), withKey: "thrust")
        
        engineWantsSound = true
        enginePlayer.play()
    }
    
    public func stopThrustAnimation() {
        self.enginePlayer.pause()
        
        self.removeAction(forKey: "sound")
        exhaustMain.removeAction(forKey: "thrust")
        exhaustLeft.removeAction(forKey: "thrust")
        exhaustRight.removeAction(forKey: "thrust")
        
        let shutdown = SKAction.scaleY(to: 0, duration: 0.1)
        exhaustMain.run(shutdown)
        exhaustLeft.run(shutdown)
        exhaustRight.run(shutdown)
        
        engineWantsSound = false
        stopAudio()
    }
    
    func stopAudio() {
        if !leftRCSWantSound && !rightRCSWantsSound && !engineWantsSound {
            enginePlayer.pause()
        }
    }
    
    public func reset() {
        rcsLeft.yScale = 0
        rcsRight.yScale = 0
        exhaustLeft.yScale = 0
        exhaustMain.yScale = 0
        exhaustRight.yScale = 0
    }
    
}
