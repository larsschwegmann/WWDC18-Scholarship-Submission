/*:
 
 # Martian Lander
 #### Lars Schwegmann
 ---
 
 ## Introduction
 
 Hello!
 
 In this Playground, I wanted to combine my love for retro games and space travel by creating a little SpriteKit powered game.
 
 The goal of the game is to safely land the Spacecraft in one of the four landing zones marked in Red.
 
 To play the game, just open the Playground LiveView, click on it once for it to receive your Keyboard events, and press Spacebar to Start! __Watch out for you Fuel consumption and your Speed__ (see top left of the Screen)!
 
 I hope you enjoy the Game!\
 \
 Lars
 
 ## Controls
 
 __W__/__Up-Arrow__: Main Engine Thruster
 
 __A__/__Left-Arrow__: Roll counter clockwise
 
 __S__/__Right-Arrow__: Roll clockwise
 
 __Spacebar__: Start/Pause game
 
 __R__: Reset Game
 
 __Note__: I recommend playing with the WASD keys. For some reason, the Arrow keys get stuck sometimes because keyUp(:) is not being called (at least on my Mac).
 
 ## Background
 
 This game is supposed to be a hommage to _Lunar Lander_ made by Atari in 1979. But instead of landing on the Moon, you land on Mars!
 
 The Terrain is procedurally generated and looks different every time the playground restarts. This was by far the hardest part of the project, as it turns out that getting visually appealing landscapes is not that easy with random numbers 😄. The Graphics were all made by me and I got the sound effects from [Freesound.org](https://freesound.org)
 
 Due to my studies, I only had roughly 2 days to create this. Nevertheless, I am very happy with the result, since I was a SpriteKit beginner when I started this project and still managed to create something that I really like on time.
 
 # 🚀
 
 */
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundSupport.PlaygroundPage.current.liveView = getSceneView()
