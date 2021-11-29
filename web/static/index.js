function makeTable(players, result) {
    let htmlTable = `<table class="table"> <thead><tr>`
    //create first col without a player
    htmlTable = `${htmlTable} <th scope="col"></th>`
    //Create table head
    for (player in players) {
        htmlTable = `${htmlTable} <th scope="col">${players[player]}</th>`
    }
    //end table head and begin table content
    htmlTable = `${htmlTable} </tr></thead><tbody>`
    let count = 0;
    for (i = 0; i < players.length; i++) {
        htmlTable = `${htmlTable} <tr>`
        for (j = 0; j < players.length + 1; j++) {
            if (j == 0) {
                htmlTable = `${htmlTable} <th scope="row">${players[i]}</th>`
            } else {
                if ((i + 1) == (j)) {
                    htmlTable = `${htmlTable} <td> x </th>`
                } else {
                    htmlTable = `${htmlTable} <td> ${result[count]} </th>`
                    count++
                }
            }
        }
        htmlTable = `${htmlTable} </tr>`
    }
    htmlTable = `${htmlTable} </tr></tbody></table>`
    return htmlTable
}

function play() {
    setMessage('Running Secret Santa Rafle (This can take a while)')
    document.getElementById("target").innerHTML = ""

    let players = []
    for (i = 1; i < 5; i++) {
        if (document.getElementById(`player${i}`).value == '' && i == 4) {

        } else if (document.getElementById(`player${i}`).value == '') {
            players[i - 1] = `Player ${i}`
        } else {
            players[i - 1] = document.getElementById(`player${i}`).value
        }
    }

    let selectElement = document.getElementById("targetSelect")
    let targetValue = selectElement.options[selectElement.selectedIndex].value;

    fetch(`./play/${targetValue}/${players.length}`)
        .then(response => {
            if(response.status == 200){
                response.json()
                .then(data => {
                    console.log(data)
                    if (!data.error) {
                        let element = document.getElementById("target")
                        element.innerHTML = makeTable(players, data.players)
                        setMessage('')
                    }else{
                        console.log(data.error)
                        setMessage(data.error)
                    }
                })
            }else{
                response.text().then(text=>{
                    console.log(text)
                    setMessage(text)
                })
            }  
        })
        .catch(err => {
            console.log(err)
        })
}

function setMessage(text){
    let messageElement = document.getElementById("message")
    messageElement.innerHTML = text
}
