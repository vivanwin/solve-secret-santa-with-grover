# Solve secret santa with Grover

This repo contains the code which was used by [this](https://vincent.frl/quantum-secret-santa/) blog post. It shows how to solve a secret sant raffle using the Grover Search algorithm.
When executed the program will try to find a solution for 3 and 4 players, then prints the results to the terminal. The output should look like this: 
```
  |A    |B    |C    |D
A |  X  |false|true |false|
B |false|  X  |false|true |
C |true |false|  X  |false|
D |false|true |false|  X  |
```
This menas that player `C` should get a small git for player `A`, player `D` for `B`, etc.

### How to use
- Make sure you have [.net core 3.X](https://dotnet.microsoft.com/download/dotnet-core) and the [QDK](https://docs.microsoft.com/en-us/quantum/quickstarts/) (Quantum development kit from Microsoft) installed.
- Inside the root folder of this project execute the project with `dotnet run`, or open the solution in visual studio and run it from there.