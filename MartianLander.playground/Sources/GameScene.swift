import PlaygroundSupport
import SpriteKit
import GameplayKit
import Cocoa

let playgroundDimensions = CGSize(width: 1024, height: 668)

let labelWidth: CGFloat = 250
let labelHeight: CGFloat = 40

let statusLabelWidth: CGFloat = 1000

let fuelLabel = NSTextField(frame: NSRect(x: playgroundDimensions.width - labelWidth, y: playgroundDimensions.height - labelHeight - 5, width: labelWidth, height: labelHeight))
let hSpeedLabel = NSTextField(frame: NSRect(x: playgroundDimensions.width - labelWidth, y: playgroundDimensions.height - 2 * labelHeight - 2*5, width: labelWidth, height: labelHeight))
let vSpeedLabel = NSTextField(frame: NSRect(x: playgroundDimensions.width - labelWidth, y: playgroundDimensions.height - 3 * labelHeight - 3 * 5, width: labelWidth, height: labelHeight))

let statusLabel = NSTextField(frame: NSRect(x: playgroundDimensions.width/2 - statusLabelWidth/2, y: playgroundDimensions.height/2 - 150, width: statusLabelWidth, height: 300))


//Game constants
let segmentCount = 30
let landingPadCount = 4
let GravityConstant = 0.2 //m/s^2

let spacecraftCategoryMask: UInt32 = 0x1
let groundCategoryMask: UInt32 = 0x10
let borderCategoryMask: UInt32 = 0x100

enum Key: UInt16 {
    case w = 13
    case a = 0
    case s = 1
    case d = 2
    case up = 126
    case left = 123
    case down = 125
    case right = 124
    case space = 49
    case reset = 15
}

class GameScene: SKScene {
    
    //SKNodes
    var spacecraft: Spacecraft!
    var explosion: SKEmitterNode!
    
    //Props for updating camera
    var segmentHeights: [CGFloat] = []
    var segmentWidth: CGFloat = 0
    var cameraCenteredAroundPlayer = false
    var originalCameraPosition: CGPoint = CGPoint.zero
    
    var gameOver = false
    
    var counter = 0
    
    //Props for update loop
    var upKeyPressed: Bool = false
    var leftKeyPressed: Bool = false
    var downKeyPressed: Bool = false
    var rightKeyPressed: Bool = false
    
    var didThrustOnLastTick: Bool = false
    var didTorqueLeftOnLastTick: Bool = false
    var didTorqueRightOnLastTick: Bool = false
    
    //LandingPad Psoitions
    var landingPadCoordinates: [(x1: CGFloat, x2: CGFloat)] = []
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        self.physicsWorld.contactDelegate = self
        self.setupScene()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        super.update(currentTime)
        //Handles all thrusting/engine control of Spacecraft
        engineControl()
        
        counter += 1
        if counter % 5 == 0 {
            updateLabels()
        }
        
        //Increase damping when not controlling spacecraft to make handling easier
        if !leftKeyPressed && !rightKeyPressed {
            spacecraft.physicsBody?.angularDamping = 7
        } else {
            spacecraft.physicsBody?.angularDamping = 2
        }
    }
    
    override func didSimulatePhysics() {
        super.didSimulatePhysics()
        
        if gameOver {
            return
        }
        
        //Get segment below the Spacecraft
        let currentSegment = Int(floor(spacecraft.position.x / CGFloat(segmentWidth)))
        
        let segmentHeight = 0.5 * (segmentHeights[currentSegment] + segmentHeights[currentSegment + 1])
        
        if abs(spacecraft.position.y - segmentHeight) < 350 {
            let scale: CGFloat = 0.5
            var position: CGPoint = spacecraft.position
            
            
            if position.x - scale * self.size.width/2 < 0 {
                //Too far left
                position = CGPoint(x: scale * self.size.width/2, y: position.y)
            } else if position.x + scale * self.size.width/2 > self.size.width {
                position = CGPoint(x: self.size.width - scale * self.size.width/2, y: position.y)
            }
            
            //Adjust camera for easier landing
            self.camera?.run(SKAction.group([SKAction.scale(to: scale, duration: 0.5), SKAction.move(to: position, duration: 0.5)]))
            cameraCenteredAroundPlayer = true
        } else {
            //Zoom back out
            if cameraCenteredAroundPlayer {
                self.camera?.run(SKAction.group([SKAction.scale(to: 1, duration: 0.5), SKAction.move(to: originalCameraPosition, duration: 0.5)]))
                cameraCenteredAroundPlayer = false
            }
        }
    }
    
    //MARK: Key Events
    
    override func keyDown(with event: NSEvent) {
        
        if gameOver {
            return
        }
        
        guard let key = Key(rawValue: event.keyCode) else {
            return
        }
        
        switch key {
        case .w, .up:
            self.upKeyPressed = true
        case .a, .left:
            self.leftKeyPressed = true
        case .s, .down:
            self.downKeyPressed = true
        case .d, .right:
            self.rightKeyPressed = true
        default:
            return
        }
    }
    
    override func keyUp(with event: NSEvent) {
        guard let key = Key(rawValue: event.keyCode) else {
            return
        }
        
        if key == .reset {
            self.resetGame()
            return
        }
        
        if gameOver {
            return
        }
        
        switch key {
        case .w, .up:
            self.upKeyPressed = false
        case .a, .left:
            self.leftKeyPressed = false
        case .s, .down:
            self.downKeyPressed = false
        case .d, .right:
            self.rightKeyPressed = false
        case .space:
            self.isPaused = !self.isPaused
            if self.isPaused {
                statusLabel.stringValue = "PAUSED"
                statusLabel.isHidden = false
            } else {
                statusLabel.stringValue = ""
                statusLabel.isHidden = true
            }
        case .reset:
            self.resetGame()
        }
    }
    
    //MARK: Custom functions
    
    func setupScene() {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -GravityConstant)
        self.backgroundColor = .black
        
        //Prepare World border
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(origin: self.frame.origin, size: self.size))
        self.physicsBody?.categoryBitMask = borderCategoryMask
        self.physicsBody?.collisionBitMask = spacecraftCategoryMask
        self.physicsBody?.contactTestBitMask = 0
        
        //Prepare Camera
        guard let camera = self.childNode(withName: "Camera") as? SKCameraNode else {
            return
        }
        self.camera = camera
        self.originalCameraPosition = camera.position
        
        //Add Spacecraft
        guard let sc = self.childNode(withName: "Spacecraft") as? Spacecraft else {
            return
        }
        self.spacecraft = sc
        self.spacecraft.physicsBody?.categoryBitMask = spacecraftCategoryMask
        self.spacecraft.physicsBody?.collisionBitMask = groundCategoryMask | borderCategoryMask
        self.spacecraft.physicsBody?.contactTestBitMask = groundCategoryMask
        
        //Prepare Stars
        guard let stars = (self.childNode(withName: "Stars") as? SKReferenceNode)?.children.first as? SKEmitterNode else {
            return
        }
        stars.advanceSimulationTime(10)
        
        //Prepare Explosion
        self.explosion = SKEmitterNode(fileNamed: "Explosion.sks")
        
        self.isPaused = true
        
        //Prepare Terrain
        self.generateTerrain()
    }
    
    func resetGame() {
        //Reset camera
        self.camera?.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1, duration: 0.5),
                SKAction.move(to: originalCameraPosition, duration: 0.5)
                ]),
            SKAction.run {
                self.isPaused = true
                self.gameOver = false
                self.cameraCenteredAroundPlayer = false
                
                //Reset Spacecraft
                self.spacecraft.position = CGPoint(x: 480, y: 1440)
                self.spacecraft.zRotation = CGFloat(90).degreesToRadians()
                self.spacecraft.fuel = 3500
                self.spacecraft.physicsBody!.velocity = CGVector(dx: 300, dy: 0)
                self.spacecraft.physicsBody?.angularVelocity = 0
                
                self.spacecraft.removeFromParent()
                self.addChild(self.spacecraft)
                
                self.updateLabels()
                statusLabel.stringValue = "Press Space to Start"
                statusLabel.textColor = .white
                statusLabel.isHidden = false
            }
            ]))
    }
    
    func updateLabels() {
        fuelLabel.stringValue = "Fuel: \(spacecraft.fuel) kg"
        hSpeedLabel.stringValue = "H. Speed: \(Int(abs(spacecraft.physicsBody!.velocity.dx/10))) m/s"
        vSpeedLabel.stringValue = "V. Speed: \(Int(spacecraft.physicsBody!.velocity.dy/10)) m/s"
    }
    
    func engineControl() {
        //Check if we need to thrust
        if upKeyPressed && spacecraft.fuel > 0 {
            if !didThrustOnLastTick {
                //Didnt thrust on last tick, start animation
                spacecraft.startThrustAnimation()
                didThrustOnLastTick = true
            }
            spacecraft.thrust()
        } else {
            if didThrustOnLastTick {
                //Did thrust on last tick, but not thrusting anymore, stop ^thrusting
                spacecraft.stopThrustAnimation()
                didThrustOnLastTick = false
            }
        }
        
        if leftKeyPressed && spacecraft.fuel > 0 {
            if !didTorqueLeftOnLastTick {
                didTorqueLeftOnLastTick = true
                spacecraft.startRightRCSAnimation()
            }
            spacecraft.applyTorqueCounterClockwise()
        } else {
            if didTorqueLeftOnLastTick {
                didTorqueLeftOnLastTick = false
                spacecraft.stopRightRCSAnimation()
            }
        }
        
        if rightKeyPressed && spacecraft.fuel > 0 {
            if !didTorqueRightOnLastTick {
                didTorqueRightOnLastTick = true
                spacecraft.startLeftRCSAnimation()
            }
            spacecraft.applyTorqueClockwise()
        } else {
            if didTorqueRightOnLastTick {
                didTorqueRightOnLastTick = false
                spacecraft.stopLeftRCSAnimation()
            }
        }
    }
    
    func generateTerrain() {
        //Determines the Y value of the leftmost ground segment coordinate
        let startSampler = GKRandomDistribution(lowestValue: -100, highestValue: 300)
        
        //Determines the change in height from segment to segment
        let samplerDY = GKRandomDistribution(lowestValue: 0, highestValue: 200)
        
        //Determines a change of direction with 1/segmentCount chance
        let boolSampler = GKRandomDistribution(lowestValue: 0, highestValue: segmentCount)
        
        //Determines where the landing pads are places
        let landingPadSampler = GKRandomDistribution(lowestValue: 2, highestValue: segmentCount - 2)
        
        //Generate landing pad segment numbers
        var padSegments: Set<Int> = []
        
        for _ in 1...landingPadCount {
            while true {
                let segment = landingPadSampler.nextInt()
                if !padSegments.contains(segment) && !padSegments.contains(segment - 1) && !padSegments.contains(segment + 1) {
                    padSegments.insert(segment)
                    break
                }
            }
            
        }
        
        
        //+1 -> Go up, -1 -> Go down
        var sign = 1
        //Divide the Scene into segments
        segmentWidth = (self.size.width / CGFloat(segmentCount))
        
        let path = CGMutablePath()
        
        //Stating point: (0, y)
        var y = CGFloat(startSampler.nextInt())
        var dy = CGFloat(samplerDY.nextInt() * sign) / segmentWidth
        path.move(to: CGPoint(x: 0, y: y))
        //dy -> Starting slope
        
        for i in 1...segmentCount + 1 {
            //Save last points height in segment heights for later use
            segmentHeights += [path.currentPoint.y]
            
            let x = segmentWidth * CGFloat(i)
            let lastDy = dy
            
            dy = CGFloat(samplerDY.nextInt() * sign) / segmentWidth
            y = y + CGFloat(samplerDY.nextInt() * sign)
            
            if padSegments.contains(i - 1) {
                let padLineWidth: CGFloat = 15.0
                
                let leftPadPoint = path.currentPoint
                let rightPadPoint = CGPoint(x: x, y: leftPadPoint.y)
                
                //Add horizontal landing pad
                path.addLine(to: rightPadPoint)
                
                //Mark Landing pad with red line
                let padPath = CGMutablePath()
                
                padPath.move(to: CGPoint(x: leftPadPoint.x, y: leftPadPoint.y))
                padPath.addLine(to: CGPoint(x: rightPadPoint.x, y: rightPadPoint.y))
                padPath.addLine(to: CGPoint(x: rightPadPoint.x, y: rightPadPoint.y - padLineWidth))
                padPath.addLine(to: CGPoint(x: leftPadPoint.x, y: leftPadPoint.y - padLineWidth))
                
                let padShapeNode = SKShapeNode(path: padPath)
                padShapeNode.strokeColor = .clear
                padShapeNode.fillColor = .red
                padShapeNode.zPosition = 3
                self.addChild(padShapeNode)
                
                self.landingPadCoordinates += [(leftPadPoint.x, rightPadPoint.x)]
                
                //Add blink
                padShapeNode.run(SKAction.repeatForever(SKAction.sequence(
                    [SKAction.fadeAlpha(to: 0.1, duration: 0.3),
                     SKAction.fadeAlpha(to: 1.0, duration: 0.3)]
                )))
            } else {
                //Add bezier curve
                path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x - segmentWidth/2, y: path.currentPoint.y + lastDy * segmentWidth/2), control2: CGPoint(x: path.currentPoint.x + segmentWidth/2, y: y - dy * segmentWidth/2))
            }
            
            //We dont want to go vertically offscreen with our terrain
            if y > 640 {
                sign = -1
            } else if y < -280 {
                sign = 1
            } else {
                if boolSampler.nextInt() == 0 {
                    sign = -sign
                }
            }
        }
        
        segmentHeights += [path.currentPoint.y]
        
        path.addLine(to: CGPoint(x: self.size.width, y: -900))
        path.addLine(to: CGPoint(x: 0, y: -900))
        
        let shapeNode = SKShapeNode(path: path)
        shapeNode.fillColor = .white
        shapeNode.strokeColor = .clear
        shapeNode.lineWidth = 0
        shapeNode.zPosition = 2
        let texture = SKTexture(imageNamed: "Ground.png")
        shapeNode.fillTexture = texture
        
        shapeNode.physicsBody = SKPhysicsBody(edgeChainFrom: path)
        shapeNode.physicsBody?.categoryBitMask = groundCategoryMask
        shapeNode.physicsBody?.collisionBitMask = spacecraftCategoryMask
        shapeNode.physicsBody?.contactTestBitMask = 0
        
        self.addChild(shapeNode)
    }
    
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        if gameOver {
            return
        }
        
        guard let nodeA = contact.bodyA.node,
            let _ = contact.bodyB.node else {
                return
        }
        
        var spacecraftBody: SKPhysicsBody
        if nodeA.name == "Spacecraft" {
            spacecraftBody = contact.bodyA
        } else {
            spacecraftBody = contact.bodyB
        }
        
        let freezeBlock = {
            self.spacecraft.reset()
            self.spacecraft.stopThrustAnimation()
            self.spacecraft.stopLeftRCSAnimation()
            self.spacecraft.stopRightRCSAnimation()
            
            self.upKeyPressed = false
            self.leftKeyPressed = false
            self.downKeyPressed = false
            self.rightKeyPressed = false
            
            self.didThrustOnLastTick = false
            self.didTorqueLeftOnLastTick = false
            self.didTorqueRightOnLastTick = false
        }
        
        if spacecraftBody.velocity.norm() > 35 {
            self.gameOver = true
            let scale = self.camera!.xScale
            self.camera!.run(SKAction.sequence([SKAction.scale(to: scale * 1.05, duration: 0.05), SKAction.scale(to: scale, duration: 0.05)]))
            //Explode!
            let explosionCopy = self.explosion.copy() as! SKEmitterNode
            explosionCopy.position = self.spacecraft.position
            self.addChild(explosionCopy)
            self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: true))
            
            //Reset all the things
            freezeBlock()
            
            self.spacecraft.removeFromParent()
            
            
            explosionCopy.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.1),
                SKAction.scale(by: 1.5, duration: 0.1),
                SKAction.run {
                    explosionCopy.particleBirthRate = 0
                },
                SKAction.wait(forDuration: 2.0),
                SKAction.run {
                    explosionCopy.removeFromParent()
                    
                    statusLabel.stringValue = "Maybe go a little slower next time 😅\n Press R to try again!"
                    statusLabel.textColor = .red
                    statusLabel.isHidden = false
                }
                ]))
        } else {
            //Check if we landed on the right spot
            let spaceCraftXPos = self.spacecraft.position.x
            
            var didWin = false
            landingPadCoordinates.forEach { (x1, x2) in
                if spaceCraftXPos > x1 && spaceCraftXPos < x2 {
                    //Win!
                    didWin = true
                }
            }
            
            if didWin {
                statusLabel.stringValue = "Successfully landed! 🚀😄"
                statusLabel.textColor = .green
                statusLabel.isHidden = false
            } else {
                statusLabel.stringValue = "You missed the target! Press R to try again!"
                statusLabel.textColor = .red
                statusLabel.isHidden = false
            }
            
            self.gameOver = true
            freezeBlock()
        }
    }
    
}

public func getSceneView() -> SKView {
    // Load the SKScene from 'GameScene.sks'
    let sceneView = SKView(frame: CGRect(origin: CGPoint.zero, size: playgroundDimensions))
    if let scene = GameScene(fileNamed: "GameScene") {
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        // Present the scene
        sceneView.presentScene(scene)
    }
    
    
    //sceneView.showsPhysics = true
    sceneView.showsFPS = true
    sceneView.ignoresSiblingOrder = true
    sceneView.showsNodeCount = true
    sceneView.showsDrawCount = true
    
    fuelLabel.backgroundColor = .clear
    fuelLabel.textColor = .white
    fuelLabel.font = NSFont.systemFont(ofSize: 32, weight: .light)
    fuelLabel.isEditable = false
    fuelLabel.isBezeled = false
    fuelLabel.isBordered = false
    fuelLabel.stringValue = "Fuel: 3500 kg"
    
    hSpeedLabel.backgroundColor = .clear
    hSpeedLabel.textColor = .white
    hSpeedLabel.font = NSFont.systemFont(ofSize: 32, weight: .light)
    hSpeedLabel.isEditable = false
    hSpeedLabel.isBezeled = false
    hSpeedLabel.isBordered = false
    hSpeedLabel.stringValue = "H. Speed: 30 m/s"
    
    vSpeedLabel.backgroundColor = .clear
    vSpeedLabel.textColor = .white
    vSpeedLabel.font = NSFont.systemFont(ofSize: 32, weight: .light)
    vSpeedLabel.isEditable = false
    vSpeedLabel.isBezeled = false
    vSpeedLabel.isBordered = false
    vSpeedLabel.stringValue = "V. Speed: 0 m/s"
    
    statusLabel.backgroundColor = .clear
    statusLabel.textColor = .white
    statusLabel.font = NSFont.systemFont(ofSize: 64, weight: .semibold)
    statusLabel.isEditable = false
    statusLabel.isBezeled = false
    statusLabel.isBordered = false
    statusLabel.alignment = .center
    statusLabel.maximumNumberOfLines = 0
    statusLabel.stringValue = "Press Space to Start"
    
    sceneView.addSubview(fuelLabel)
    sceneView.addSubview(hSpeedLabel)
    sceneView.addSubview(vSpeedLabel)
    sceneView.addSubview(statusLabel)
    
    return sceneView
}
