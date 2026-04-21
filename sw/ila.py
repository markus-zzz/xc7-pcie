from telnetlib3.sync import TelnetConnection
import time

class JtagILA:

  def __init__(self, openocd_host, openocd_port):
    self._openocd_host = openocd_host
    self._openocd_port = openocd_port
    self._HexToBin = {
      '0': '0000',
      '1': '0001',
      '2': '0010',
      '3': '0011',
      '4': '0100',
      '5': '0101',
      '6': '0110',
      '7': '0111',
      '8': '1000',
      '9': '1001',
      'a': '1010',
      'b': '1011',
      'c': '1100',
      'd': '1101',
      'e': '1110',
      'f': '1111'
    }
    self.readStatus()

  def writeCtrl(self, start, stop):
    with TelnetConnection(self._openocd_host, self._openocd_port) as conn:
      conn.readline()
      conn.readline()
      conn.write('irscan xc7.tap 2\r\n')
      conn.readline()
      conn.readline()
      cmd = (self._post_trig_cntr << 16) | (0x2 if stop else 0) | (0x1 if start else 0)
      #print(hex(cmd))
      conn.write('drscan xc7.tap 64 {}\r\n'.format(hex(cmd)))
      resp = conn.readline()
      resp = conn.readline()

  def readStatus(self):
    with TelnetConnection(self._openocd_host, self._openocd_port) as conn:
      conn.readline()
      conn.readline()
      conn.write('irscan xc7.tap 2\r\n')
      conn.readline()
      conn.readline()
      conn.write('drscan xc7.tap 64 0\r\n')
      resp = conn.readline()
      resp = conn.readline()
      resp = resp[1:] # Get rid of prefix
      self._depth = int(resp[0:4], 16)
      self._width = int(resp[4:8], 16)
      self._trigidx = int(resp[8:12], 16)
      self._triggerd = int(resp[12:16], 16) & 2 != 0
      self._running = int(resp[12:16], 16) & 1 != 0

  def readData(self):
    self._data = []
    with TelnetConnection(self._openocd_host, self._openocd_port) as conn:
      conn.readline()
      conn.readline()
      conn.write('irscan xc7.tap 3\r\n')
      conn.readline()
      conn.readline()
      jtag_data_skip = 3
      conn.write('drscan xc7.tap {} 0\r\n'.format(self._depth * self._width + jtag_data_skip))
      resp = conn.readline()
      resp = conn.readline()
      hexdata = resp[1:] # Get rid of prefix
      hexdata = hexdata.strip('\r\n')
      # Convert to binary string
      bindata = ""
      for hexdigit in hexdata:
        bindata = bindata + self._HexToBin[hexdigit]

      bindata = bindata[0:-jtag_data_skip]
      # Split binary string into one string for each sample
      for d in reversed(range(1, self._depth + 1)):
        self._data.append(bindata[-self._width:])
        bindata = bindata[:-self._width]

  def setTrigPos(self, pos): # pos in range [0,1]
    self._post_trig_cntr = int(self._depth * pos)

  def waitTrigger(self):
    while True:
      self.readStatus()
      print("\rdepth: {} width: {} trigidx: {} triggerd: {} running: {}".format(self._depth, self._width, self._trigidx, self._triggerd, self._running), end='')
      if self._triggerd:
        break
      time.sleep(1)

  def printData(self):
    offset = self._trigidx + self._post_trig_cntr
    print('\n==========================')
    print('offset: {} trigidx: {} post_trig_cntr: {}'.format(offset, self._trigidx, self._post_trig_cntr))
    for idx in range(self._depth):
      idx2 = (offset + idx) % self._depth
      d = self._data[idx2]
      print('{:5d} {} : {} {}'.format(idx, 'T' if idx2 == self._trigidx else ' ', d, hex(int(d, 2))))

#
#
#

ila = JtagILA(openocd_host='localhost', openocd_port=4444)
ila.setTrigPos(0.80)
ila.readStatus()
ila.writeCtrl(start=True, stop=False)
ila.waitTrigger()
ila.readStatus()
ila.readData()
ila.printData()
ila.readStatus()
