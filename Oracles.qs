namespace Quantum.SecretSanta {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;


    operation Oracle_And (queryRegister : Qubit[], target : Qubit) : Unit is Adj {
        Controlled X(queryRegister, target);
    }

    operation Oracle_Or (queryRegister : Qubit[], target : Qubit) : Unit is Adj {
        within {
            // Flip input qubits to negate them
            ApplyToEachA(X, queryRegister);
        } apply {
            // Use the AND oracle to get the AND of negated inputs
            Oracle_And(queryRegister, target);
        }
        // Flip the target to get the final answer
        X(target);
    }

    operation Oracle_Xor (queryRegister : Qubit[], target : Qubit) : Unit is Adj {
        ApplyToEachA(CNOT(_, target), queryRegister); 
    }

    operation Oracle_Exactly1One (queryRegister : Qubit[], target : Qubit) : Unit is Adj {
        for (i in 0 .. Length(queryRegister) - 1) {
            (ControlledOnInt(2^i, X))(queryRegister, target);
        }
    }
}
