/* --------------------------------------------------------------------------
 * SimpleOpenNI NITE Slider2d
 * --------------------------------------------------------------------------
 * Processing Wrapper for the OpenNI/Kinect library
 * http://code.google.com/p/simple-openni
 * --------------------------------------------------------------------------
 * prog:  Max Rheiner / Interaction Design / zhdk / http://iad.zhdk.ch/
 * date:  03/28/2011 (m/d/y)
 * ----------------------------------------------------------------------------
 *
 * ----------------------------------------------------------------------------
 */
import SimpleOpenNI.*;

SimpleOpenNI          context;

// NITE
XnVSessionManager     sessionManager;
XnVSelectableSlider2D trackPad;

int gridX = 7;
int gridY = 5;

Trackpad   trackPadViz;

// unlock point sequence
int[] xPoints = new int[4];
int[] yPoints = new int[4];

void setup()
{
  context = new SimpleOpenNI(this,SimpleOpenNI.RUN_MODE_MULTI_THREADED);
   
  // mirror is by default enabled
  context.setMirror(true);
  
  // enable depthMap generation 
  context.enableDepth();
  
  // enable the hands + gesture
  context.enableGesture();
  context.enableHands();
 
  // setup NITE 
  sessionManager = context.createSessionManager("Click,Wave", "RaiseHand");

  trackPad = new XnVSelectableSlider2D(gridX,gridY);
  sessionManager.AddListener(trackPad);

  trackPad.RegisterItemHover(this);
  trackPad.RegisterValueChange(this);
  trackPad.RegisterItemSelect(this);
  
  trackPad.RegisterPrimaryPointCreate(this);
  trackPad.RegisterPrimaryPointDestroy(this);

  // create gui viz
  trackPadViz = new Trackpad(new PVector(context.depthWidth()/2, context.depthHeight()/2,0),
                                         gridX,gridY,50,50,15);  

  size(context.depthWidth(), context.depthHeight()); 
  smooth();
  
   // info text
  println("-------------------------------");  
  println("1. Wave till the tiles get green");  
  println("2. The relative hand movement will select the tiles");  
  println("-------------------------------");   

  String fileName = "data/data.txt";
  readFile(fileName);
}

void draw()
{
  // update the cam
  context.update();
  
  // update nite
  context.update(sessionManager);
  
  // draw depthImageMap
  image(context.depthImage(),0,0);
  
  trackPadViz.draw();
}

void keyPressed()
{
  switch(key)
  {
  case 'e':
    // end sessions
    sessionManager.EndSession();
    println("end session");
    break;
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// session callbacks

void onStartSession(PVector pos)
{
  println("onStartSession: " + pos);
}

void onEndSession()
{
  println("onEndSession: ");
}

void onFocusSession(String strFocus,PVector pos,float progress)
{
  println("onFocusSession: focus=" + strFocus + ",pos=" + pos + ",progress=" + progress);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// XnVSelectableSlider2D callbacks

void onItemHover(int nXIndex,int nYIndex)
{
  println("onItemHover: nXIndex=" + nXIndex +" nYIndex=" + nYIndex);
  
  trackPadViz.update(nXIndex,nYIndex);
}

void onValueChange(float fXValue,float fYValue)
{
 // println("onValueChange: fXValue=" + fXValue +" fYValue=" + fYValue);
}

void onItemSelect(int nXIndex,int nYIndex,int eDir)
{
  println("onItemSelect: nXIndex=" + nXIndex + " nYIndex=" + nYIndex + " eDir=" + eDir);
  trackPadViz.push(nXIndex,nYIndex,eDir);
}

void onPrimaryPointCreate(XnVHandPointContext pContext,XnPoint3D ptFocus)
{
  println("onPrimaryPointCreate");
  
  trackPadViz.enable();
}

void onPrimaryPointDestroy(int nID)
{
  // println("onPrimaryPointDestroy");
  
  trackPadViz.disable();
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// save and read data from file
void readFile(String fileName)
{
  String[] lines = loadStrings(fileName);
  
  if (lines.length != 4)
  {
    println("Must have exactly 4 points");  
  }
  else
  {
    for (int i = 0; i < lines.length; i++)
    {
      xPoints[i] = int(split(lines[i], ' ')[0]);
      yPoints[i] = int(split(lines[i], ' ')[1]);    
    }

    println(xPoints);
    println(yPoints);  
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Trackpad

class Trackpad
{
  int     xRes;
  int     yRes;
  int     width;
  int     height;
  
  boolean active;
  PVector center;
  PVector offset;
  
  int      space;
  
  int      focusX;
  int      focusY;
  int      selX;
  int      selY;
  int      dir;
  
  int      unlockCount = 0;
  
  Trackpad(PVector center,int xRes,int yRes,int width,int height,int space)
  {
    this.xRes     = xRes;
    this.yRes     = yRes;
    this.width    = width;
    this.height   = height;
    active        = false;
    
    this.center = center.get();
    offset = new PVector();
    offset.set(-(float)(xRes * width + (xRes -1) * space) * .5f,
               -(float)(yRes * height + (yRes -1) * space) * .5f,
               0.0f);
    offset.add(this.center);
    
    this.space = space;
  }
  
  void enable()
  {
    active = true;
    
    focusX = -1;
    focusY = -1;
    selX = -1;
    selY = -1;
  }
  
  void update(int indexX,int indexY)
  {
    focusX = indexX;
    focusY = (yRes-1) - indexY;
  }
  
  void push(int indexX,int indexY,int dir)
  {
    selX = indexX;
    selY =  (yRes-1) - indexY;
    this.dir = dir;
    
    if (unlockCount < 3) {
      println("unlock count: " + unlockCount);
      println("1: " + selX + " " + selY);
      println("2: " + xPoints[unlockCount] + " " + yPoints[unlockCount]);  
    }
    
    if (unlockCount >= 3) 
    {
      println("System unlocked");
    }
    else if (selX == xPoints[unlockCount] && selY == yPoints[unlockCount])
    { 
      unlockCount++;
    }
    else
    {
      println("Failed to unlock");
    }
  }
  
  void disable()
  {
    active = false;
  }
  
  void draw()
  {    
    pushStyle();
    pushMatrix();
    
      translate(offset.x,offset.y);
    
      for(int y=0;y < yRes;y++)
      {
        for(int x=0;x < xRes;x++)
        {
          if(active && (selX == x) && (selY == y))
          {
            // selected object 
            fill(100,100,220,190);
            strokeWeight(3);
            stroke(100,200,100,220);
          }
          else if(active && (focusX == x) && (focusY == y))
          { 
            // focus object 
            fill(100,255,100,220);
            strokeWeight(3);
            stroke(100,200,100,220);
          }
          else if(active)
          {  // normal
            strokeWeight(3);
            stroke(100,200,100,190);
            noFill();
          }
          else
          {
            strokeWeight(2);
            stroke(200,100,100,60);
            noFill();
          }
           rect(x * (width + space),y * (width + space),width,height);  
        }
      }
    popMatrix();
    popStyle();  
  }
}
