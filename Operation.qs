namespace QuantumSecretSanta {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Convert;

    // This function returns only the qubits from the input register which are defined in the clause
    function GetClauseQubits (queryRegister : Qubit[], clause: (Int, Bool)[]) : Qubit[] {
        mutable clauseQubits = new Qubit[0];
        for ((index, _) in clause) {
            set clauseQubits += [queryRegister[index]];
        }
        return clauseQubits;
    }

    // Evaluates the query against a specified clause, which a specified gate.
    operation Oracle_SATClause (queryRegister : Qubit[], target : Qubit, clause : (Int, Bool)[], clauseType : String) : Unit is Adj {
        within {
            for ((index, positive) in clause) {
                if (not positive) {
                    X(queryRegister[index]);
                }
            }
        } apply {
            let clauseQubits = GetClauseQubits(queryRegister, clause); 

            // These statements allow, users to use different types of gates in each term of the SAT problem
            if (clauseType == "XOR") {
                Oracle_Xor(clauseQubits, target);
            }
            if (clauseType == "ONE") {
                Oracle_Exactly1One(clauseQubits, target);
            }
            if (clauseType == "OR") {
                Oracle_Or(clauseQubits, target);
            }
            if (clauseType == "AND") {
                Oracle_And(clauseQubits, target);
            }
        }
    }

    operation Oracle_SAT (queryRegister : Qubit[], target : Qubit, problem : (Int, Bool)[][], clauseTypes : String[]) : Unit is Adj {
        using (auxiliaryRegister = Qubit[Length(problem)]) {
            // Compute the clauses.
            within {
                for (i in 0 .. Length(problem) - 1) {
                    Oracle_SATClause(queryRegister, auxiliaryRegister[i], problem[i], clauseTypes[i]);
                }
            }
            // Evaluate the overall formula using an AND oracle.
            apply {
                Oracle_And(auxiliaryRegister, target);
            }
        }
    }

 
    operation Oracle_Converter (markingOracle : ((Qubit[], Qubit) => Unit is Adj), register : Qubit[]) : Unit is Adj {
        using (target = Qubit()) {
            // Put the target into the |-⟩ state and later revert the state
            within { 
                X(target);
                H(target); 
            }
            // Apply the marking oracle; since the target is in the |-⟩ state,
            // flipping the target if the register satisfies the oracle condition will apply a -1 factor to the state
            apply { 
                markingOracle(register, target);
            }
        }
    }


    operation GroversLoop (register: Qubit[], oracle: ((Qubit[], Qubit) => Unit is Adj), numIterations: Int) : Unit {
        let phaseOracle = Oracle_Converter(oracle, _);
        ApplyToEach(H, register);

        for (_ in 1 .. numIterations) {
            phaseOracle(register);
            within {
                ApplyToEachA(H, register);
                ApplyToEachA(X, register);
            } 
            apply {
                Controlled Z(Most(register), Tail(register));
            }
        }
    }

    // Main function to run the Grover search 
    operation RunGroversSearch (N : Int, oracle : ((Qubit[], Qubit) => Unit is Adj)) : Bool[] {
        // Try different numbers of iterations.
        mutable answer = new Bool[N];
        using ((register, output) = (Qubit[N], Qubit())) {
            mutable correct = false;
            mutable iter = 1;
            repeat {
                Message($"Trying search with {iter} iterations");
                GroversLoop(register, oracle, iter);
                let res = MultiM(register);
            
                oracle(register, output);
                if (MResetZ(output) == One) {
                    set correct = true;
                    set answer = ResultArrayAsBoolArray(res);
                }
                ResetAll(register);
            } until (correct or iter > 30)  // The fail-safe to avoid going into an infinite loop
            fixup {
                set iter *= 2;
            }
            if (not correct) {
                fail "Failed to find an answer";
            }
        }
        Message($"{answer}");
        return answer;
    }

    // Create an array of SAT terms for our problem; all variables are present in the clauses in affirmative.
    // Input: Array of Int [0,1]
    // Return: Array of tuples representing a SAT term [(0, true), (1, true)]
    operation GenerateSAT(terms : Int[]) : (Int, Bool)[] {
        let N = Length(terms);
        mutable arr = new (Int, Bool)[N];
        for (i in 0 .. N - 1) {
            set arr w/= i <- (terms[i], true);
        }
        return arr;
    }

    // Generate a matrix with possible variables
    // Input: total number of players
    // Return example for 3 players:
    //  |1|2|3|
    // 1|x|0|1|
    // 2|2|x|3|
    // 3|4|5|x|
    // in 3d array form: [[0, 1], [2, 3], [4, 5]]
    operation CreateVariablesArray(players : Int) : Int [][] {
        mutable variablesArray = new Int[][players];
        mutable count = 0;
        for (i in 0 .. players - 1) {
            mutable rowArray = new Int[0];
            for (j in 0 .. players - 1) {
                if (j != i) {
                    set rowArray += [count];
                    set count += 1;
				} else {
                    set rowArray += [0];
                }
            }
            set variablesArray w/= i <- rowArray;
        }
        return variablesArray;
    }

    // Given the total number of players, generate a 3d array of tuples representing the SAT
    // problem for the Secret Santa raffle.
    // Input: total number or players
    // Return: 2d array of tuple representing the SAT problem
    operation CreateSatTerm(players : Int) : (Int, Bool)[][] {
        let totalVariables = players * 2;
        let varibleNamesArray = CreateVariablesArray(players);

        // Because we need all the unique values in both the vertical and horizontal,
        // we create a temporary arrays for the horizontal and vertical
        mutable intArray = new Int[][totalVariables];
        for (i in 0 .. players - 1) {
            mutable tmpArrayHor = new Int[0];
            mutable tmpArrayVer = new Int[0];
            for (j in 0 .. players - 1) {
                if (i != j) {
                    set tmpArrayHor += [varibleNamesArray[i][j]];
                    set tmpArrayVer += [varibleNamesArray[j][i]];
			    }
            }
            set intArray w/= i <- tmpArrayHor;
            set intArray w/= (i + players) <- tmpArrayVer;
        }
        
        mutable totalArray = new (Int,Bool)[][0];
        for (i in 0 .. Length(intArray) - 1) {
            set totalArray += [GenerateSAT(intArray[i])];
        }
        return totalArray;
    }


    @EntryPoint()
    operation RunSecretSanta (NumPlayers : Int) : Bool[] {
        // Simulate the raffle with 3 and with 4 people
        // for (players in 3 .. 4) {
        if(NumPlayers < 3 or NumPlayers > 4){
            Message("Number of players must be either 3 or 4");
            return [false];
        }
        else{
            Message($"Simulate the Secret Santa raffle with {NumPlayers} people");
            let totalQubits = NumPlayers * NumPlayers - NumPlayers;     // The number of variables that will be used
            let clauseTypes = ConstantArray(2 * NumPlayers, "ONE");     // The gates that will be used, e.g. ["ONE", "ONE", ....]
            let problem = CreateSatTerm(NumPlayers);                    // The SAT problem string, e.g. [[(0, true), (1, true)]]

            let oracle = Oracle_SAT(_, _, problem, clauseTypes);        // Create an oracle from the SAT and problem types
            let result = RunGroversSearch(totalQubits, oracle);         // Run the Grover search on the problem
            PrintResults(result, NumPlayers);                           // Nicely print the results

            return result;
        }
    }

    // Outputs the result on the console to see who has picked who.
    operation PrintResults(result : Bool[], N: Int) : Unit{
        let names = ["A","B","C","D","E"];
        
        mutable count = 0;
        
        for (i in 0 .. N) {
            mutable line = "";
            for (j in 0 .. N) {
                if (i == 0) {
                    if (j != 0) {
                        set line += $"|{names[j - 1]}    ";
                    } else {
                        set line += "  ";
                    }
                } else {
					if (j == 0) {
                        set line += $"{names[i - 1]} |";
                    } else {
                        if (i == j) {
                            set line += "  X  |";
                        } else {
                            if (result[count]) {
                                set line += $"true |";
                            } else {
                                set line += $"false|";
                            }
                            set count += 1;
                        }
                    }
                }
            }
            Message(line);
        }
    }
}
