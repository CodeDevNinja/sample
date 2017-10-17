module("luci.controller.api.pppoemanage", package.seeall)
-- sqlite3 = require "luasql.sqlite3"
-- local env  = sqlite3.sqlite3()
-- local conn = env:connect('ipHistory.sqlite')
-- print(env,conn)
-- luci.http.write(env)
--require "luasql.mysql"


success= '{"flag":"success"}'
fail='{"flag":"fail"}'
function index()
	entry({"api","pppoe", "list"},call("iface_status"),"iface_status",1).dependent=false
	entry({"api","pppoe", "connect"},call("iface_reconnect"),"iface_reconnect",1).dependent=false
	entry({"api","pppoe", "stop"},call("iface_shutdown"),"iface_shutdown",1).dependent=false
	entry({"api","pppoe", "delete"},call("iface_delete"),"iface_delete",1).dependent=false
	entry({"api","pppoe", "waibu_api"},call("waibu_api"),"waibu_api",1).dependent=false
	--entry({"api", "pppoe","add"}, call("pppoeadd"), _("add"), nil).dependent = false
	--entry({"api", "pppoe","zone"}, call("fwzone_write"), _("zone"), nil).dependent = false
	--entry({"api", "pppoe","port"}, call("port_forward"), _("port"), nil).dependent = false
	--entry({"api", "pppoe","port"}, call("wrote"), _("port"), nil).dependent = false
	--entry({"api", "pppoe","ipHis"}, call("iface_ipHis"), _("ipHis"), nil).dependent = false
	--entry({"api", "status", "realtime", "connections_status"}, call("action_connections"),nil).dependent = false
	--entry({"api", "status", "connections_rate"}, call("activeConnection"),nil,1).dependent = false
	--entry({"api", "session", "sessionLog"}, call("sessionLog")).dependent = false



end
--添加账号
function pppoeadd()
	local  name=luci.http.formvalue("name") 
	local  adapter=luci.http.formvalue("adapter") 
	local  username=luci.http.formvalue("username") 
	local  password=luci.http.formvalue("password") 
	local  zone=luci.http.formvalue("zone") 
	utl = require "luci.util"
	write(self,name,'pppoe',username,password,adapter,zone)
	--validate(self,name,'')
end
function write(self,name ,value,username,password,adapter,zone)
	local utl = require "luci.util"
	local uci = require "luci.model.uci".cursor()
	local nw  = require "luci.model.network".init()
	local name = name--newnet:formvalue(section)
	if name and #name > 0 then
		local br = "bridge"--("1" == "1") and "bridge" or nil
		local net = nw:add_network(name, { proto = value, type = br })
		if net then
			local ifn
			for ifn in utl.imatch(
				br and 'eth0' or 'eth1'
			) do
			--ifn=adapter
			--net:add_interface(ifn)
			end
		--	fwzone_write(name)
			--fwzone_write(name,zone)
			nw:save("network")
			nw:save("wireless")
		fwzone_write(name)

		luci.sys.call("uci set network."..name..".username="..username.." && uci set network."..name..".password="..password.." && uci set network."..name..".ifname="..adapter)	
		luci.http.write('{"flag":"success"}')
		else
		luci.http.write('{"flag":"fail"}')
		end
	end
end
--断开连接
function iface_shutdown(iface)
	local iface 
	iface=luci.http.formvalue("iface")
	local netmd = require "luci.model.network".init()
	local net = netmd:get_network(iface)
	if net then
		luci.sys.call("env -i /sbin/ifdown %q >/dev/null 2>/dev/null" % iface)
		luci.http.write(success)
		return
	end
	luci.http.write(fail)
end
--删除
function iface_delete(iface)
	local iface 
	iface=luci.http.formvalue("iface")
	local netmd = require "luci.model.network".init()
	local net = netmd:del_network(iface)
	if net then
		luci.sys.call("env -i /sbin/ifdown %q >/dev/null 2>/dev/null" % iface)
		--luci.http.redirect(luci.dispatcher.build_url("admin/network/network"))
		netmd:commit("network")
		netmd:commit("wireless")
		luci.http.write(success)
		return
	end
	luci.http.write(fail)
	--luci.http.status(404, "No such interface")
end
--连接
function iface_reconnect(iface)
	local iface 
	iface=luci.http.formvalue("iface")
	local netmd = require "luci.model.network".init()
	local net = netmd:get_network(iface)
	local ip  = get_ip(iface)
	local wId = tonumber(string.sub(iface,5,-1))
	local tId = wId+90
	local sId = 30+wId
	if ip~=nil then
		success='{"flag":"success","old_ip":"'..ip..'","new_ip":"'
		else
		success='{"flag":"success","old_ip":"nil","new_ip":"'
	end
	if net then
		luci.sys.call("sh /root/celueluyou.sh")
		luci.sys.call("env -i /sbin/ifup %q >/dev/null 2>/dev/null" % iface)--拨号操作
	end
		local new_ip=ip
		--[[if new_ip==nil	then
		else		
		end	
		--]]
		local t0 = os.clock()--获取当前时间
		while(new_ip==nil or ip==new_ip)--新ip等于旧ip或者新ip为空 暂停死循环
		do
		new_ip=get_ip(iface)
			if os.clock() - t0 >= 5--拨号超时5秒为失败
			then
			luci.http.write(fail)
			return	
			end 
		end
		luci.sys.call("iptables -t nat -A POSTROUTING -s 192.168.3."..sId.."/255.255.255.0 -o "..wId.." -j MASQUERADE")
		luci.sys.call("ip rule add from 192.168.3."..sId.." lookup "..tId)
		luci.sys.call("ip route add default dev pppoe-wan_"..wId.." table "..tId)
		success=success..new_ip..'"}'
		local date=os.date("%Y-%m-%d %H:%M:%S");
		local str = '{"time":"'..date..'","ip":"'..new_ip..'"}'
		if io.open(iface..".txt")~=nil then
			file=io.open(iface..'.txt',"a")
			file:write(","..str)
			else
			file=io.open(iface..'.txt',"w+")
			file:write(str)
		end
		file:close()
		luci.http.write(success)
		return
end

--查看IP历史记录
function iface_ipHis(iface)
	local iface 
	iface=luci.http.formvalue("iface")
	file=io.open('./'..iface..'.txt',"r")
	str= file:read("*a")
	luci.http.write('['..str..']')
end





--查看
function waibu_api(ifaces)
	local uci = require("luci.model.uci").cursor()
	ifaces=luci.http.formvalue("ifaces")
	if ifaces=="all" then
	uci:foreach("network", "interface",
		function (section)
		local ifc = section[".name"]
			if ifc ~= "loopback" then
			ifaces=ifaces..ifc..","	
			end
		end)
	end
	local netm = require "luci.model.network".init()
	local rv   = { }
	local proxy = { }
	local iface
	for iface in ifaces:gmatch("[%w%.%-_]+") do
		local net = netm:get_network(iface)
		local device = net and net:get_interface()
		--luci.http.write(string.sub(iface,0,2))

	 if iface ~= 'alllan' and string.sub(iface,0,3)~='lan'then 
	 		local wId = tonumber(string.sub(iface,5,-1))
		 if device then
		 	local _, a			
			local data = {
				--id   = iface,
				user = 'user'..wId,
				pwd = '123',
				ip    = get_ip(iface),
				port =  math.random(3128 ,3135)
			}
		if data.ip ~=nil and #proxy<20 then
		proxy[#proxy+1] = data
		end
		else
			rv[#rv+1] = {
				id   = iface,
				name = iface,
				type = "ethernet"
			}
		end
	 end
	end
	--luci.http.write(rv)
	--rv['port']= {'3128','3129','3130','3131','3132','3133','3134','3135'}
	--rv['lines']=proxy
	if #proxy > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(proxy)
		return
	end
	luci.http.write(fail)
	--luci.http.status(404, "No such device")
end

--查看
function iface_status(ifaces)
	local uci = require("luci.model.uci").cursor()
	ifaces=luci.http.formvalue("ifaces")
	if ifaces=="all" then
	uci:foreach("network", "interface",
		function (section)
		local ifc = section[".name"]
			if ifc ~= "loopback" then
			ifaces=ifaces..ifc..","
			--file=io.open("l.lua","a+")	
			--file:write(ifc:upper())		
			end
		end)
	end
	local netm = require "luci.model.network".init()
	local rv   = { }
	local proxy = { }
	local iface
	for iface in ifaces:gmatch("[%w%.%-_]+") do
		local net = netm:get_network(iface)
		local device = net and net:get_interface()
		--luci.http.write(string.sub(iface,0,2))

	 if iface ~= 'alllan' and string.sub(iface,0,3)~='lan'then 
	 		local wId = tonumber(string.sub(iface,5,-1))
		 if device then
			local data = {
				id         = iface,
				username = 'user'..wId,
				password = '',
				proto      = net:proto(),
				uptime     = net:uptime(),
				gwaddr     = net:gwaddr(),
				dnsaddrs   = net:dnsaddrs(),
				name       = device:shortname(),
				type       = device:type(),
				ifname     = device:name(),
				macaddr    = device:mac(),
				is_up      = device:is_up(),
				rx_bytes   = device:rx_bytes(),
				tx_bytes   = device:tx_bytes(),
				rx_packets = device:rx_packets(),
				tx_packets = device:tx_packets(),
				ipaddrs    = { },
				ip6addrs   = { },
				subdevices = { }
			}
			local _, a
			for _, a in ipairs(device:ipaddrs()) do
				data.ipaddrs[#data.ipaddrs+1] = {
					addr      = a:host():string(),
					netmask   = a:mask():string(),
					prefix    = a:prefix()
				}
			end
			for _, a in ipairs(device:ip6addrs()) do
				if not a:is6linklocal() then
					data.ip6addrs[#data.ip6addrs+1] = {
						addr      = a:host():string(),
						netmask   = a:mask():string(),
						prefix    = a:prefix()
					}
				end
			end

			for _, device in ipairs(net:get_interfaces() or {}) do
				data.subdevices[#data.subdevices+1] = {
					name       = device:shortname(),
					type       = device:type(),
					ifname     = device:name(),
					macaddr    = device:mac(),
					macaddr    = device:mac(),
					is_up      = device:is_up(),
					rx_bytes   = device:rx_bytes(),
					tx_bytes   = device:tx_bytes(),
					rx_packets = device:rx_packets(),
					tx_packets = device:tx_packets(),
				}
			end
			proxy[#proxy+1] = data
		 else
			rv[#rv+1] = {
				id   = iface,
				name = iface,
				type = "ethernet"
			}
		 end
	 end
	end
	--luci.http.write(rv)
	rv['port']= {'3128','3129','3130','3131','3132','3133','3134','3135','3136','3137','3138','3139','3140','3141','3142','3143'}
	rv['host'] = '192.168.0.75'
	rv['lines']=proxy
	if #proxy > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end
	luci.http.write(fail)
	--luci.http.status(404, "No such device")
end
function get_ip(iface)
	local uci = require("luci.model.uci").cursor()
	local netm = require "luci.model.network".init()
	local net = netm:get_network(iface)
	local device = net and net:get_interface()
	local _, a
		for _, a in ipairs(device:ipaddrs()) do
				return a:host():string()
		end
end


--设置网口的firewall的zone
--uci get firewall.@zone[-1].network
-- uci get firewall.@zone[-1].network=wan_999
function fwzone_write(ifaces)
	--local ifaces = luci.http.formvalue("ifaces")
	--[[local zone=luci.sys.call("uci get firewall.wan.network")

	file=io.open("ww.lua","a+")
	file:write("uci set firewall.wan.network='"..zone.."'")--]]

	--zone=zone.." "..ifaces
luci.sys.call("uci add_list firewall.wan.network='"..ifaces.."'")

		--[[local fw = require "luci.model.firewall".init()
		local nw  = require "luci.model.network".init()
		section="wan_999"
		value="wan22"
		local zone = fw:get_zone(value)
		--luci.http.write(zone[1])
		if not zone and value == '-' then
			value = m:formvalue(self:cbid(section) .. ".newzone")
			if value and #value > 0 then
				zone = fw:add_zone(value)
			else
				fw:del_network(section)
			end
		end
		if zone then
			fw:del_network(section)
			zone:add_network(section)
		end
		nw:save("network")--]]
end

function port_forward(self)	
	local n=luci.http.formvalue("name")
	local p=luci.http.formvalue("proto")
	local E = luci.http.formvalue("extzone")
	local e = luci.http.formvalue("extport")
	local I = luci.http.formvalue("intzone")
	local a = luci.http.formvalue("intaddr")
	local i = luci.http.formvalue("intport")
	luci.sys.call("uci add firewall redirect && uci set firewall.@redirect[-1].dest="..I.." && uci set firewall.@redirect[-1].name="..n.." && uci set firewall.@redirect[-1].src="..E.." && uci set firewall.@redirect[-1].target=DNAT && uci set firewall.@redirect[-1].proto="..p.." && uci set firewall.@redirect[-1].dest_port="..i.." && uci set firewall.@redirect[-1].src_dport="..e.." && uci set firewall.@redirect[-1].dest_ip="..a.." && uci commit")
	return
end

function wrote()
	luci.http.write(success)
end

function action_connections()
	local sys = require "luci.sys"

	luci.http.prepare_content("application/json")

	luci.http.write("{ connections: ")
	luci.http.write_json(sys.net.conntrack())

	local bwc = io.popen("luci-bwc -c 2>/dev/null")
	if bwc then
		luci.http.write(", statistics: [")

		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end

		luci.http.write("]")
		bwc:close()
	end

	luci.http.write(" }")
end

function activeConnection()
	--local activeRate=luci.http.formvalue("status")

	local conn_count = tonumber((
			luci.sys.exec("wc -l /proc/net/nf_conntrack") or
			luci.sys.exec("wc -l /proc/net/ip_conntrack") or
	""):match("%d+")) or 0

	local conn_max = tonumber((	
			luci.sys.exec("sysctl net.nf_conntrack_max") or
			luci.sys.exec("sysctl net.ipv4.netfilter.ip_conntrack_max") or
			""):match("%d+")) or 4096
	local rate = string.format("%0.3f", conn_count/conn_max) *100 
	local json = '{"conn_max":'..tostring(conn_max)..',"conn_count":'..tostring(conn_count)..',"rate":"'..tostring(rate)..'%"}'
	luci.http.write(json)



end

-- function sessionLog()
-- 	--file=io.open('../tmp/logs/access.log',"r")
-- 	-- 以只读方式打开文件
-- 	--file = io.open("../tmp/logs/access.log", "r")
-- 	--file:seek("end")

-- 	-- 设置默认输入文件为 test.lua
-- 	--	io.input(file)
-- 	-- 输出文件第一行
-- 	--local session=io.read()
-- 	--创建环境对象
-- 	env = luasql.mysql()

-- 	--连接数据库
-- 	conn = env:connect("lccserver","root2","root2","192.168.0.111",3305)

-- 	--设置数据库的编码格式
-- 	conn:execute"SET NAMES UTF8"

-- 	--local t =os.clock()
-- 	--cur = conn:execute("INSERT INTO proxy_sessions (time,client_ip,current_ip,host_ip,status_code,host,method,response_time,size,auth)VALUES('"..arr[1].."','"..arr[2].."','"..arr[3].."','"..arr[4].."','"..arr[5].."',"..arr[1].."','"..arr[2].."','"..arr[3].."','"..arr[4].."'")
-- -- while true do
--  --local secondTime = os.clock()
--  -- if 	secondTime-t>60 then
-- 	local current_ip = "NONE"
-- 	for line in io.lines("../tmp/logs/access.log") do
-- 		local arr = {}
-- 		for info in string.gmatch(line, "%S+") do
-- 	    --json='{"timestamp":'..arr[1]}
-- 	    table.insert(arr,info)
-- 	    --luci.http.write(""..arr[1])
-- 		end
-- 		if arr[8]~="-" then
-- 			--luci.http.write("wan_"..string.sub(arr[8],4,-1))

-- 			current_ip=get_ip("wan_"..string.sub(arr[8],5,-1))

-- 		end
-- 			cur = conn:execute("INSERT INTO proxy_sessions (time,client_ip,current_ip,host_ip,status_code,host,method,response_time,size,auth)VALUES('"..arr[1].."','"..arr[3].."','"..current_ip.."','"..arr[9].."','"..arr[4].."','"..arr[7].."','"..arr[6].."','"..arr[2].."','"..arr[5].."','"..arr[8].."')")
-- 		--json=json..'{"timestamp":'..arr[1]..',"responseTime":'..arr[2]..',"clientIp":"'..arr[3]..'","statusCode":"'..arr[4]..'","size":'..arr[5]..',"method":"'..arr[6]..'","host":"'..arr[7]..'","auth":"'..arr[8]..'","hostIp":"'..arr[9]..'"},'
-- 	end
-- 	--luci.http.write('['..json..']')
		
-- 	--conn:close()  --关闭数据库连接
-- 	--env:close()   --关闭数据库环境

-- 	--t=secondTime
-- 	luci.sys.call("squid -k rotate")
-- 	luci.sys.call("rm -rf  /tmp/logs/*.log.*")
-- 	--os.execute("sleep " .. 60)
--  -- end
--  --end
-- end




