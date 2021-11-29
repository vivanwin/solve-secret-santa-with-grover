from fastapi import FastAPI, Request, Response, status
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

import qsharp
import qsharp.azure
from QuantumSecretSanta import RunSecretSanta


# UNCOMMENT IF YOU WANT TO USE CLOUD SIMULATOR OR HARDWARE!
# qsharp.azure.connect(resourceId="/subscriptions/.../Microsoft.Quantum/Workspaces/WORKSPACE_NAME", location="West Europe")

app = FastAPI()

app.mount("/static/", StaticFiles(directory="web/static/"), name="static")

async def runAsync(num_players: int):
    qsharp.reload()
    result = RunSecretSanta.simulate(NumPlayers=num_players)
    return result

@app.get("/", response_class=FileResponse)
def read_index():
    path = 'web/index.html' 
    return FileResponse(path)

@app.get("/play/{target}/{num_players}")
async def run_sim(target: str, num_players: int, response: Response):
    if target == 'local':
        result = await runAsync(num_players)
        return {"players": result}

    elif target == 'simulator' or target == 'hardware':
        try:
            if target == 'simulator':
                qsharp.azure.target("honeywell.hqs-lt-s1-sim")
            else:
                qsharp.azure.target("honeywell.hqs-lt-s1")
            result = qsharp.azure.execute(RunSecretSanta, NumPlayers=num_players, shots=500, jobName="RunSecretSanta - {}".format(target))
            return {"players": result}
        except Exception as err:
            print(err)
            response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
            return {"error":err.error_description}
    
    else:
        return {"error": "provide valid target"}