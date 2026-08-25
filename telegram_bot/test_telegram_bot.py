import tempfile,time,unittest
from pathlib import Path
from telegram_bot import CommandRouter,InternetMonitor,_encode_length,_decode_length,_parse_sentence
from telegram_bot.security import TelegramPolicy, AuditTrail
class FakeTelegram:
 def __init__(self): self.messages=[]; self.documents=[]; self.callback_answers=[]
 def send_message(self,c,t,reply_markup=None): self.messages.append((c,t,reply_markup))
 def answer_callback_query(self,c): self.callback_answers.append(c)
 def send_document(self,c,f,x): self.documents.append((c,f,x))
class FakeGateway:
 address='10.0.0.1'
 def __init__(self): self.calls=[]; self.internet_ok=True; self.rx_byte=2048; self.tx_byte=1024
 def close(self): pass
 def command(self,path,*args):
  self.calls.append((path,args))
  if path=='/tool/user-manager/profile/print': return [{'!type':'!re','name':'basic','rate-limit':'2M/2M'},{'!type':'!re','name':'premium'},{'!type':'!done'}]
  if path=='/tool/user-manager/user/print' and (not args or any('=.proplist=.id' in a for a in args)): return [{'!type':'!re','.id':'*1'},{'!type':'!re','.id':'*2'},{'!type':'!done'}]
  if path=='/tool/user-manager/user/print': return [{'!type':'!re','username':args[0].split('=',1)[1]},{'!type':'!done'}]
  if path=='/ping': return [{'!type':'!re','status':'success' if self.internet_ok else 'timeout'},{'!type':'!done'}]
  if path=='/interface/print': return [{'!type':'!re','name':'ether1','rx-byte':str(self.rx_byte),'tx-byte':str(self.tx_byte),'running':'yes','disabled':'no'},{'!type':'!done'}]
  if path=='/system/resource/print': return [{'!type':'!re','uptime':'1d','version':'6.49.10','cpu-load':'12','free-memory':'80','total-memory':'128'},{'!type':'!done'}]
  if path=='/ip/dhcp-server/lease/print': return [{'!type':'!re','status':'bound'},{'!type':'!done'}]
  if path=='/tool/user-manager/session/print': return [{'!type':'!re','user':'card01'},{'!type':'!done'}]
  if path=='/ip/service/print': return [{'!type':'!re','name':'api','port':'8728','disabled':'no'},{'!type':'!re','name':'api-ssl','port':'8729','disabled':'yes'},{'!type':'!done'}]
  if path=='/log/print': return [{'!type':'!re','time':'12:00','topics':'system','message':'ready'},{'!type':'!done'}]
  return [{'!type':'!re','name':'demo'},{'!type':'!done'}]
class Tests(unittest.TestCase):
 def test_protocol(self):
  for n in [0,1,127,128,4095,16384,1000000]:
   e=_encode_length(n)
   class R:
    def __init__(s,v):s.v=v;s.i=0
    def read(s,c):x=s.v[s.i:s.i+c];s.i+=c;return x
   self.assertEqual(_decode_length(R(e)),n)
  self.assertEqual(_parse_sentence(['!re','=x=y'])['x'],'y')
 def test_reads_and_print_projection(self):
  g=FakeGateway();t=FakeTelegram();r=CommandRouter(g,t,policy=TelegramPolicy(),admin_user_ids=frozenset({'9'}));r.handle('1','9','/status');r.handle('1','9','/print active');self.assertTrue(any('=.proplist=' in a for _,args in g.calls for a in args))
 def test_user_details_are_read_only(self):
  g=FakeGateway();t=FakeTelegram();r=CommandRouter(g,t,policy=TelegramPolicy(),admin_user_ids=frozenset({'9'}));r.handle('1','9','/users card01');self.assertIn('card01',t.messages[-1][1]);self.assertTrue(any(path=='/tool/user-manager/user/print' for path,_ in g.calls));self.assertFalse(any(path.endswith('/add') for path,_ in g.calls))
 def test_reboot_binds_user_and_confirmation(self):
  g=FakeGateway();t=FakeTelegram();r=CommandRouter(g,t,policy=TelegramPolicy(),admin_user_ids=frozenset({'9'}));r.handle('1','9','/reboot'); data=t.messages[-1][2]['inline_keyboard'][0][0]['callback_data'];r.handle_callback('1','8','cb',data);self.assertNotIn('/system/reboot',[x[0] for x in g.calls]);r.handle_callback('1','9','cb2',data);self.assertEqual(g.calls[-1][0],'/system/reboot')
 def test_reboot_expiry(self):
  g=FakeGateway();t=FakeTelegram();r=CommandRouter(g,t,policy=TelegramPolicy(),admin_user_ids=frozenset({'9'}));r.handle('1','9','/reboot');nonce=next(iter(r._pending_reboots));r._pending_reboots[nonce]=('1','9',time.time()-1,'test-operation');r.handle_callback('1','9','cb',f'reboot:{nonce}:confirm');self.assertNotIn('/system/reboot',[x[0] for x in g.calls])
 def test_reboot_requires_admin_user(self):
  g=FakeGateway();t=FakeTelegram();r=CommandRouter(g,t,policy=TelegramPolicy(),admin_user_ids=frozenset({'10'}));r.handle('1','9','/reboot');self.assertFalse(r._pending_reboots)
 def test_policy_requires_chat_and_user(self):
  policy=TelegramPolicy(); self.assertTrue(policy.authorize(chat_id='1',user_id='9',allowed_chats=frozenset({'1'}),allowed_users=frozenset({'9'}))); self.assertFalse(policy.authorize(chat_id='1',user_id='8',allowed_chats=frozenset({'1'}),allowed_users=frozenset({'9'})))
 def test_audit_contains_no_secret_fields(self):
  with tempfile.TemporaryDirectory() as d:
   path=Path(d)/'audit.jsonl'; audit=AuditTrail(path); audit.record(source='Telegram',user_id='9',chat_id='1',command='/reboot',risk='HIGH_RISK',authorization='ALLOW',confirmation='CONFIRMED',device='10.0.0.2',result='SUCCESS',duration_ms=4); text=path.read_text(); self.assertIn('operation_id',text); self.assertNotIn('password',text.lower()); self.assertNotIn('token',text.lower())
 def test_monitor_states(self):
  g=FakeGateway();t=FakeTelegram();m=InternetMonitor(g,t,frozenset({'1'}),'1.1.1.1',30);g.internet_ok=False;self.assertEqual(m.observe_once(),'INTERNET_DOWN');g.internet_ok=True;self.assertEqual(m.observe_once(),'ONLINE')
 def test_card_pdf(self):
  g=FakeGateway();t=FakeTelegram();r=CommandRouter(g,t,policy=TelegramPolicy(),admin_user_ids=frozenset({'9'}));r.handle('1','9','554377');data=t.messages[-1][2]['inline_keyboard'][0][0]['callback_data'];r.handle_callback('1','9','cb',data);self.assertTrue(t.documents[0][2].startswith(b'%PDF'))
if __name__=='__main__':unittest.main()
