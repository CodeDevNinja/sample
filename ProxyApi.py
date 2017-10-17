from sanic import Sanic
from sanic.response import text
from urllib import request

ROUTE = {"iplist":"http://192.168.0.75/cgi-bin/luci/api/pppoe/waibu_api/?ifaces=all"}

def getJson():
	try:
           return request.urlopen(ROUTE.get("iplist")).read().decode('utf-8')
	except:
 			return "server error"  	
                #pass
def get_ip():
     ipAddress=request.urlopen("http://1212.ip138.com/ic.asp")
     content = ipAddress.read().decode('gb2312').encode('utf-8')
     ip = content[content.index('[')+1:content.index(']')]


app = Sanic(__name__)

@app.route("/getiplist")
async def test(request):
    return text(getJson())

@app.route("/getip")
async def getip(request):
    return text(get_ip())




app.run(host="0.0.0.0", port=45654, debug=False,workers=20)
