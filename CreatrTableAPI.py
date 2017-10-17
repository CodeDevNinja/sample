from sanic import Sanic
from sanic.response import json
import subprocess


class CreateTable:
    def __init__(self):
        pass

    def execute_cmd(self, name, force_flag="force"):
        cml = "cd /opt/java/hbase-observer && " + "java -jar target/observer-0.8.0-jar-with-dependencies.jar " + name + " " + force_flag
        ret = subprocess.Popen(["ssh", "root@192.168.0.241", cml], stdout=subprocess.PIPE);
        return ret


ct = CreateTable()
app = Sanic(__name__)


@app.route("/create_table", methods=['POST'])
async def post_handler(request):
    dic = eval(request.body.decode('utf-8'))
    result = ct.execute_cmd(dic.get("table"), dic.get("table"))
    return json(result)


app.run(host="0.0.0.0", port=8807, debug=False, workers=2)
