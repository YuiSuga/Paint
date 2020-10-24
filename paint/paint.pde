//must add following library:Tablet

//Tablet reference:
//    http://processing.andrescolubri.net/libraries/tablet/
//    http://processing.andrescolubri.net/libraries/tablet/reference/index.html

import codeanticode.tablet.*;
Tablet tablet;

/////////////////////////////////////////////////////////////////////////////////////////////
//parameters
/////////////////////////////////////////////////////////////////////////////////////////////
final int maxlayer=5;
int laynum=0;
PGraphics bg;
PGraphics[] layers=new PGraphics[maxlayer];
PGraphics drawLayer;

PImage pen;
PImage eraser;
PImage pen_button;
PImage eraser_button;
boolean ispen = true;

float drawsize=25;
float drawopacity=1;
color drawcolor;
boolean size_moving=false;
boolean opacity_moving=false;

int margin;
int canvas_width=960;
int canvas_height=480;

int hue=0;
float r=0,g=0,b=0;
float[] circxy=new float[2];
boolean hue_moving=false;
boolean map_moving=false;
PGraphics cmap;
PGraphics cbar;

undos ud;
int undomax;
boolean stroke_start=true;

float[][] gaussianFilter;
int filter_width=5;
boolean filter_width_moving=false;

/////////////////////////////////////////////////////////////////////////////////////////////
//setup
/////////////////////////////////////////////////////////////////////////////////////////////
void setup() {
  size(960, 1280);
  tablet = new Tablet(this); 
  
  background(128);
  stroke(0);
  smooth(8);

  //white background
  bg=createGraphics(canvas_width,canvas_height);
  bg.beginDraw();
  bg.background(255);
  bg.endDraw();

  //transparent layers
  for(int i=0;i<maxlayer;i++){
    layers[i]=createGraphics(canvas_width,canvas_height,JAVA2D);
    layers[i].beginDraw();
    layers[i].background(255,0);
    layers[i].endDraw();
  }
  drawLayer=layers[laynum];
  ud=new undos(10);

  pen=loadImage("shodo_fude.png");
  eraser=loadImage("bunbougu_keshigomu.png");
  pen_button=loadImage("shodo_fude.png");
  eraser_button=loadImage("bunbougu_keshigomu.png");
  pen_button.resize(50,50);
  eraser_button.resize(50,50);
  pen_button.loadPixels();
  eraser_button.loadPixels();
  for(int w=0;w<pen_button.width;w++){
    for(int h=0;h<pen_button.height;h++){
      color pc=pen_button.pixels[h*pen_button.width+w];
      color ec=eraser_button.pixels[h*eraser_button.width+w];
      if(pc!=color(0,0,0,0))
        pen_button.pixels[h*pen_button.width+w]=color(2*green(pc),2*green(pc),2*green(pc));
      if(ec!=color(0,0,0,0))
        eraser_button.pixels[h*eraser_button.width+w]=color(2*green(ec),2*green(ec),2*green(ec));
    }
  }
  pen_button.updatePixels();
  eraser_button.updatePixels();

  textFont(createFont("Tempus Sans ITC",24));

  margin=height/4;
  cmap=colorMap(hue);
  cbar=colorBar();

  circxy[0]=width/4*1.5;
  circxy[1]=height/4*1.5+100;

  gaussianFilter=gaussian(1,filter_width);

  frameRate(120);
}

/////////////////////////////////////////////////////////////////////////////////////////////
//draw
/////////////////////////////////////////////////////////////////////////////////////////////
void draw() {
  drawLayer=layers[laynum];

  background(128);
  
  if(ispen){
    drawcolor=color(r,g,b);
  }
  else{
    drawcolor=color(255,255,255);
  }

  if (mousePressed && mouseInCanvas()) {
    if(stroke_start){
      ud.add(laynum,layers[laynum]);
      stroke_start=false;
    }
    drawLayer.beginDraw();

    if(ispen){
      cursor(pen,0,0);
      drawcolor=color(r,g,b);
    }
    else{
      cursor(eraser,0,32);
      drawcolor=color(255,255,255);
    }

    float prs=drawsize*tablet.getPressure();
    float preprs=drawsize*tablet.getSavedPressure();

    if(tablet.getPressure()==0.0 && preprs==0.0){//mouse's pressure
        prs=drawsize/2;
        preprs=drawsize/2;
    }

    //low pressure => low opacity
    drawLayer.stroke(drawcolor,(50+50*tablet.getPressure())*drawopacity);

    float sub=prs-preprs;
    float dx=mouseX-pmouseX,dy=mouseY-pmouseY;
    float sx=pmouseX,sy=pmouseY;
    float tmpx=sx,tmpy=sy;

    //draw line with stroke weight changing gradually
    pushMatrix();
    drawLayer.translate(0,-margin);

    for(float i=0.0;i<=1;i+=0.01){
        drawLayer.strokeWeight(preprs+sub*i);
        drawLayer.line(tmpx,tmpy,sx+dx*i,sy+dy*i);
        tmpx=sx+dx*i;
        tmpy=sy+dy*i;
    }

    drawLayer.endDraw();
    popMatrix();
    
  }
  else{
      cursor(ARROW);
  }


  //canvas
  pushMatrix();
  translate(0,margin);
  drawImage();
  popMatrix();

  //layers
  pushMatrix();
  drawLayers();
  popMatrix();

  //colors
  pushMatrix();
  scale(2,2);
  image(cmap,width/4*1.5,height/4*1.5);
  image(cbar,width/4*1.5,height/4*1.4);
  fill(255,180);
  stroke(32,80);
  ellipse(circxy[0],circxy[1], 10, 10);
  rect(width/4*1.5+hue-2.5,height/4*1.4,5,10);
  fill(drawcolor);
  rect(width/4*1.8,height/4*1.85,40,40);
  popMatrix();

  //debug:draw undo list
  //drawlist();

  //pen/eraser button
  drawTools();

  //filters button
  drawFilters();

  //undo button
  drawUndo();

  //save button
  drawSave();

  //save tablet state
  tablet.saveState();
}

/////////////////////////////////////////////////////////////////////////////////////////////
//mouse/keyboard functions
/////////////////////////////////////////////////////////////////////////////////////////////
void mousePressed(){
  //layer change
  if(mouseX<=200){
    if(mouseY>=880){
      for(int i=0;i<maxlayer;i++){
        if(mouseY<=950+i*80){
          ud.add(laynum,layers[laynum]);
          laynum=maxlayer-(i+1);
          break;
        }
      }
    }
  }

  //hue change
  if(mouseX>=width/2*1.5 && mouseY>=height/2*1.4 && mouseX<=width/2*1.5+200 && mouseY<=height/2*1.4+20){
    hue_moving=true;
    hue=(int)((mouseX-width/2*1.5)/2);
    cmap=colorMap(hue);
    color c=cmap.pixels[(int)(circxy[1]-height/4*1.5)*101+(int)(circxy[0]-width/4*1.5)];
    r=red(c);g=green(c);b=blue(c);
    drawcolor=color(r,g,b);
  }
  else hue_moving=false;

  //colormap change
  if(mouseX>=width/2*1.5 && mouseY>=height/2*1.5 && mouseX<=width/2*1.5+200 && mouseY<=height/2*1.5+200){
    map_moving=true;
    circxy[0]=mouseX/2;
    circxy[1]=mouseY/2;
    cmap.loadPixels();
    color c=cmap.pixels[(int)(mouseY-height/2*1.5)/2*101+(int)(mouseX-width/2*1.5)/2];
    r=red(c);g=green(c);b=blue(c);
    drawcolor=color(r,g,b);
  }
  else map_moving=false;

  //tool change
  if(mouseX>=width/5*3 && mouseX<=width/5*3+70 && mouseY>=height/9*7-35 && mouseY<=height/9*7+35)
    ispen=true;
  if(mouseX>=width/5*3 && mouseX<=width/5*3+70 && mouseY>=height/9*7+65 && mouseY<=height/9*7+135)
    ispen=false;

  //brush size change
  if(mouseX>=width/5*3-130 && mouseX<=width/5*3+70 && mouseY>=height/9*7+175 && mouseY<=height/9*7+200){
    drawsize=500*((mouseX-(width/5*3-130))/200.0);
    size_moving=true;
  }
  else size_moving=false;

  //opacity change
  if(mouseX>=width/5*3-130 && mouseX<=width/5*3+70 && mouseY>=height/9*7+240 && mouseY<=height/9*7+265){
    drawopacity=1.0*((mouseX-(width/5*3-130))/200.0);
    opacity_moving=true;
  }
  else opacity_moving=false;

  //filters
  if(mouseX>=width-180 && mouseX<=width-10){
    //gaussian
    if(mouseY>=35 && mouseY<=75){
      pushMatrix();
      translate(width-180,35);
      fill(150,150,150,50);
      stroke(255,255,255);
      rect(0,0,170,40);
      popMatrix();

      PImage filtered=filtering(drawLayer.get(),gaussianFilter,filter_width);
      drawLayer.loadPixels();
      filtered.loadPixels();
      drawLayer.pixels=filtered.pixels;
      drawLayer.updatePixels();
      ud.add(laynum,layers[laynum]);

      println("gaussian filter completed");
    }

    //bilateral
    if(mouseY>=85 && mouseY<=125){
      pushMatrix();
      translate(width-180,85);
      fill(150,150,150,50);
      stroke(255,255,255);
      rect(0,0,170,40);
      popMatrix();

      PImage filtered=bilateral_filtering(drawLayer.get(),filter_width/2,filter_width/2);
      drawLayer.loadPixels();
      filtered.loadPixels();
      drawLayer.pixels=filtered.pixels;
      drawLayer.updatePixels();
      ud.add(laynum,layers[laynum]);

      println("bilateral filter completed");
    }

    //mosaic
    if(mouseY>=135 && mouseY<=175){
      pushMatrix();
      translate(width-180,135);
      fill(150,150,150,50);
      stroke(255,255,255);
      rect(0,0,170,40);
      popMatrix();

      PImage filtered=mosaic(drawLayer.get(),filter_width);
      drawLayer.loadPixels();
      filtered.loadPixels();
      drawLayer.pixels=filtered.pixels;
      drawLayer.updatePixels();
      ud.add(laynum,layers[laynum]);

      println("mosaic completed");
    }

    //sharp
    if(mouseY>=185 && mouseY<=225){
      pushMatrix();
      translate(width-180,185);
      fill(150,150,150,50);
      stroke(255,255,255);
      rect(0,0,170,40);
      popMatrix();

      PImage filtered=unsharp(drawLayer.get(),filter_width+(filter_width+1)%2);
      drawLayer.loadPixels();
      filtered.loadPixels();
      drawLayer.pixels=filtered.pixels;
      drawLayer.updatePixels();
      ud.add(laynum,layers[laynum]);

      println("sharp completed");
    }
  }

  //filter width
  if(mouseX>=width-210 && mouseX<=width-190 && mouseY>=35 && mouseY<=margin-100){
    filter_width=20-20*(mouseY-35)/(margin-135);
    if(filter_width==0)filter_width=1;
    gaussianFilter=gaussian(1,filter_width+(filter_width+1)%2);
    filter_width_moving=true;
  }
  else filter_width_moving=false;


  //undo redo
  if(mouseX>=width/5*2-10 && mouseX<=width/5*2+60 && mouseY>=margin+canvas_height+20 && mouseY<=margin+canvas_height+60)
    undo();
  if(mouseX>=width/2-10 && mouseX<=width/2+60 && mouseY>=margin+canvas_height+20 && mouseY<=margin+canvas_height+60)
    redo();

  
  //save
  if(mouseX>=5 && mouseX<=75 && mouseY>=5 && mouseY<=45){
    pushMatrix();
    noFill();
    stroke(255);
    rect(5,5,70,40);
    popMatrix();
    saveImage();
  }
}

void mouseDragged() {
  //hue change
  if(hue_moving){
    float mx=mouseX;
    mx=min(max(mx,width/2*1.5),width/2*1.5+200);//adjust in range

    hue=(int)((mx-width/2*1.5)/2);
    cmap=colorMap(hue);
    color c=cmap.pixels[(int)(circxy[1]-height/4*1.5)*101+(int)(circxy[0]-width/4*1.5)];
    r=red(c);g=green(c);b=blue(c);
    drawcolor=color(r,g,b);
  }

  //colormap change
  if(map_moving){
    float mx=mouseX,my=mouseY;
    //adjust in range
    mx=min(max(mx,width/2*1.5),width/2*1.5+200);
    my=min(max(my,height/2*1.5),height/2*1.5+200);

    circxy[0]=mx/2;
    circxy[1]=my/2;
    cmap.loadPixels();
    color c=cmap.pixels[(int)(my-height/2*1.5)/2*101+(int)(mx-width/2*1.5)/2];
    r=red(c);g=green(c);b=blue(c);
    drawcolor=color(r,g,b);
  }

  //brush size change
  if(size_moving){
    float mx=mouseX;
    mx=min(max(mx,width/5*3-130),width/5*3+70);//adjust in range
    drawsize=500*((mx-(width/5*3-130))/200.0);
  }

  //opacity change
  if(opacity_moving){
    float mx=mouseX;
    mx=min(max(mx,width/5*3-130),width/5*3+70);//adjust in range
    drawopacity=1.0*((mx-(width/5*3-130))/200.0);
  }

  //filter width
  if(filter_width_moving){
    float my=mouseY;
    my=min(max(my,35),margin-100);//adjust in range
    filter_width=20-20*(int(my)-35)/(margin-135);
    if(filter_width==0)filter_width=1;
    gaussianFilter=gaussian(1,filter_width+(filter_width+1)%2);
  }
}


void mouseReleased() {
  stroke_start=true;//undo timing
}

boolean ctrlPressed=false;
void keyPressed(){
  if (key == CODED) {
    if (keyCode == CONTROL) {
      ctrlPressed = true;
    }
  }

  if(ctrlPressed){
    if(keyCode==65){
      undo();
    }
    final int z=65+('z'-'a'),y=65+('y'-'a');
    switch(keyCode){
      case z:
        undo();
        break;
      case y:
        redo();
        break;
    }
  }

  switch(key){
    case ' ':
      ispen=!ispen;
      break;
    case 'z':
      undo();
      break;
    case 'x':
      redo();
      break;
    case 'n':
      laynum=(laynum+1)%5;
      break;
    case 'b':
      laynum=laynum!=0?(laynum-1):4;
      break;
  }
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == CONTROL) {
      ctrlPressed = false;
    }
  }
} 

boolean mouseInCanvas(){
  return (mouseX<=canvas_width)&&(mouseY>=margin)&&(mouseY<=margin+canvas_height);
}

/////////////////////////////////////////////////////////////////////////////////////////////
//colors
/////////////////////////////////////////////////////////////////////////////////////////////
PGraphics colorMap(int h){
    PGraphics pg;
    pg = createGraphics(101,101);
    pg.beginDraw();
    pg.loadPixels();
    pg.colorMode(HSB,100);
    colorMode(HSB,100);
    for(int i=0;i<=100;i+=1){
        for(int j=0;j<=100;j+=1){
            pg.pixels[i*101+j]=color(h,j,100-i);
        }
    }
    colorMode(RGB,255);
    pg.colorMode(RGB);
    pg.noFill();
    pg.stroke(32);
    pg.rect(0,0,100,100);
    pg.updatePixels();
    pg.endDraw();
    return pg;
}

PGraphics colorBar(){
    PGraphics pg;
    pg=createGraphics(100,10);
    pg.beginDraw();
    pg.colorMode(HSB,100);
    for(int i=0;i<=100;i++){
        pg.stroke(i,100,100);
        pg.line(i,0,i,10);
    }
    pg.colorMode(RGB);
    pg.noFill();
    pg.stroke(32);
    pg.rect(0,0,100,100);
    pg.endDraw();
    return pg;
}

/////////////////////////////////////////////////////////////////////////////////////////////
//undo/redo
/////////////////////////////////////////////////////////////////////////////////////////////
class undos{
    ArrayList<Integer> lay_undo=new ArrayList<Integer>();
    ArrayList<PImage> undolist=new ArrayList<PImage>();
    int undomax;

    ArrayList<Integer> lay_redo=new ArrayList<Integer>();
    ArrayList<PImage> redo=new ArrayList<PImage>();

    public undos(int listsize){
        undomax=listsize;
    }

    public void add(int n,PGraphics pg){
        lay_undo.add(n);
        undolist.add(pg.get());
        lay_redo.clear();
        redo.clear();
    }
    public int getn(int lay_now){
        if(lay_undo.isEmpty())return -1;
        int n=lay_undo.remove(lay_undo.size()-1);
        if(lay_redo.isEmpty()){lay_redo.add(lay_now);}
        lay_redo.add(n);
        return n;
    }

    public PImage getundo(PGraphics pg){
        if(undolist.isEmpty())return createImage(1,1,RGB);
        PImage img=undolist.remove(undolist.size()-1);

        if(redo.isEmpty()){redo.add(pg.get());}
        redo.add(img);
        return img;
    }

    public int getredonum(){
        if(lay_redo.isEmpty())return -1;
        int n=lay_redo.remove(lay_redo.size()-1);
        lay_undo.add(n);
        return n;
    }
    public PImage getredo(){
        if(redo.isEmpty())return createGraphics(1,1);
        PImage img=redo.remove(redo.size()-1);
        undolist.add(img);
        return img;
    }

    public void sizechange(int listsize){
        if(listsize<5){
            println("too little undo size!");
            return;
        }
        if(listsize<undomax && listsize<undolist.size()){
            for(int i=listsize;i<undolist.size();i++){
                undolist.remove(0);
            }
        }
        undomax=listsize;
    }
}

void undo(){
  int n=ud.getn(laynum);
  if(n!=-1){
    PImage und=ud.getundo(drawLayer);
    pushMatrix();
    noFill();
    stroke(255);
    rect(width/5*2-10,margin+canvas_height+20,70,40);
    popMatrix();
        
    layers[n].beginDraw();
    layers[n].loadPixels();
    und.loadPixels();
    layers[n].pixels=und.pixels;
    layers[n].updatePixels();
    layers[n].endDraw();
    laynum=n;
  }
}

void redo(){
  int m=ud.getredonum();
  if(m!=-1){
    PImage und=ud.getredo();
    pushMatrix();
    stroke(255);
    noFill();
    rect(width/2-10,margin+canvas_height+20,70,40);
    popMatrix();

    layers[m].loadPixels();
    und.loadPixels();
    layers[m].pixels=und.pixels;
    layers[m].updatePixels();
    laynum=m;
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////
//convert white => transparent
/////////////////////////////////////////////////////////////////////////////////////////////
// reference:
//  https://forum.processing.org/one/topic/proper-way-to-go-from-pgraphics-to-pimage.html
//  https://kougaku-navi.hatenablog.com/entry/20161030/p1
void transparency(PGraphics pg){
  PGraphics result=pg;
  PImage img=pg.get();
  img.loadPixels();
  result.loadPixels();
  for(int i=0;i<result.width;i++){
    for(int j=0;j<result.height;j++){
        color c=img.get(i,j);

        //white ==> transparent color
        if(red(c)>=240 && green(c)>=240 && blue(c)>=240){
          result.pixels[j*result.width+i]=color(255,255,255,0);
        }
        else{
          result.pixels[j*result.width+i]=img.get(i,j);
        }
    }
  }
  result.updatePixels();
  pg.pixels=result.pixels;
}

/////////////////////////////////////////////////////////////////////////////////////////////
//draw GUI parts
/////////////////////////////////////////////////////////////////////////////////////////////
void drawImage(){
  image(bg,0,0);
  for(int i=0;i<maxlayer;i++){
      transparency(layers[i]);
      image(layers[i],0,0);
  }
}

void drawLayers(){
  for(int i=0;i<maxlayer;i++){
    fill(150,150,150,50);
    stroke(100,100,100);
    if(i==laynum)stroke(255,255,255);
    pushMatrix();
    translate(0,height-80-80*i);
    rect(0,0,200,70);
    popMatrix();
    fill(255,255,255);text("layer"+i,10,height-20-80*i);
    text("layer"+i,10,height-20-80*i);
  }


  pushMatrix();
  scale(0.1,0.1);
  for(int i=0;i<maxlayer;i++){
    image(layers[i],800,10*height-650-800*i);
  }
  popMatrix();
}

void drawTools(){
  color selected=color(255,255,255);
  color notselected=color(100,100,100);
  pushMatrix();
  translate(width/5*3,height/9*7-35);
  fill(150,150,150,50);
  if(ispen)stroke(selected);
  else stroke(notselected);
  rect(0,0,70,70);
  fill(255,255,255);
  image(pen_button,10,15);

  translate(0,100);
  fill(150,150,150,50);
  if(ispen)stroke(notselected);
  else stroke(selected);
  rect(0,0,70,70);
  fill(255,255,255);
  image(eraser_button,10,10);

  translate(-130,100);
  text("brush size "+drawsize,0,0);
  translate(0,10);
  fill(150,150,150,50);
  stroke(100,100,100);
  rect(0,0,200,25);
  fill(255,255,255);
  rect(0,0,200*(drawsize/500.0),25);
  translate(0,50);
  text("opacity "+drawopacity,0,0);
  translate(0,10);
  fill(150,150,150,50);
  stroke(100,100,100);
  rect(0,0,200,25);
  fill(255,255,255);
  rect(0,0,200*drawopacity,25);
  popMatrix();
}

void drawFilters(){
  pushMatrix();
  translate(width-180,5);
  text("filters",50,20);
  translate(0,30);
  fill(150,150,150,50);
  stroke(100,100,100);
  triangle(-10,0,-30,0,-20,margin-100);
  rect(0,0,170,40);
  fill(255,255,255);
  text("filter width "+filter_width,-165,margin-100);
  triangle(-20+10*filter_width/20,(margin-100)*(20-filter_width)/20,-20-10*filter_width/20,(margin-100)*(20-filter_width)/20, -20,margin-100);
  text("Gaussian filter",20,30);
  translate(0,50);
  fill(150,150,150,50);
  stroke(100,100,100);
  rect(0,0,170,40);
  fill(255,255,255);
  text("Bilateral filter",20,30);
  translate(0,50);
  fill(150,150,150,50);
  stroke(100,100,100);
  rect(0,0,170,40);
  fill(255,255,255);
  text("Mosaic",50,30);
  translate(0,50);
  fill(150,150,150,50);
  stroke(100,100,100);
  rect(0,0,170,40);
  fill(255,255,255);
  text("Unsharp mask",20,30);
  popMatrix();
}

void drawUndo(){
  pushMatrix();
  fill(150,150,150,50);
  stroke(100,100,100);
  rect(width/5*2-10,margin+canvas_height+20,70,40);
  rect(width/2-10,margin+canvas_height+20,70,40);
  fill(255,255,255);
  text("undo",width/5*2,margin+canvas_height+50);
  text("redo",width/2,margin+canvas_height+50);
  popMatrix();
}

void drawSave(){
  pushMatrix();
  fill(150,150,150,50);
  stroke(100,100,100);
  rect(5,5,70,40);
  fill(255,255,255);
  text("save",20,30);
  popMatrix();
}

void drawlist(){
    pushMatrix();
    scale(0.2,0.2);
    noFill();stroke(255);
    for(int i=0;i<ud.undolist.size();i++){
        pushMatrix();
        scale(5,5);
        text(i,ud.undolist.get(i).width/5*i,30);
        if(i==ud.undolist.size()-1)text("↑",ud.undolist.get(i).width/5*i,60);
        popMatrix();
        
        rect(ud.undolist.get(i).width*i,0,ud.undolist.get(i).width*i+ud.undolist.get(i).width,ud.undolist.get(i).height);
        image(ud.undolist.get(i),ud.undolist.get(i).width*i,0);
    }
    popMatrix();
}

/////////////////////////////////////////////////////////////////////////////////////////////
//save
/////////////////////////////////////////////////////////////////////////////////////////////
void saveImage(){
  PImage result=createImage(canvas_width,canvas_height,ARGB);
  result.loadPixels();
  for(int i=0;i<maxlayer;i++){
    layers[i].loadPixels();
    for(int w=0;w<canvas_width;w++){
      for(int h=0;h<canvas_height;h++){
        color c=layers[i].pixels[h*canvas_width+w];
        if(red(c)<240 || green(c)<240 || blue(c)<240)
          result.pixels[h*canvas_width+w]=layers[i].pixels[h*canvas_width+w];
      }
    }
  }
  result.updatePixels();

  String y=String.valueOf(year());
  String m=month()/10>0?String.valueOf(month()):"0"+String.valueOf(month());
  String d=day()/10>0?String.valueOf(day()):"0"+String.valueOf(day());
  String h=hour()/10>0?String.valueOf(hour()):"0"+String.valueOf(hour());
  String mi=minute()/10>0?String.valueOf(minute()):"0"+String.valueOf(minute());
  String s=second()/10>0?String.valueOf(second()):"0"+String.valueOf(second());

  String saveplace="./Saved Images/"+y+m+d+h+mi+s+".png";

  result.save(saveplace);
  println("saved at "+saveplace);
}

/////////////////////////////////////////////////////////////////////////////////////////////
//filters
/////////////////////////////////////////////////////////////////////////////////////////////
float[][] gaussian(float s,int w) {
  int hw=w/2;
	float[][] filter = new float[w][w];
	float sum = 0;
	for(int j = -hw; j <= hw; j++)
		for(int i = -hw; i <= hw; i++)  // 1/(2\pi * \sigma^2) is omitted
			sum += filter[j + hw][i + hw] = exp(-(i * i + j * j) / 2. / s / s);

	for(int i = 0; i < w * w; i++) // nomilize filter weights(sum = 1)
		filter[int(i / w)][i % w] /= sum; // 1D index converts 2D index
	return filter;
}

PImage filtering(PImage img, float f[][],int w){
  int hw=w/2;
	PImage filteredImg = createImage(img.width, img.height, ALPHA);
	img.loadPixels();
	filteredImg.loadPixels();
	for(int j = 0; j < img.height; j++){ // scan image
		for(int i = 0; i < img.width; i++){
			float sum_r = .0, sum_g = .0, sum_b = .0, sum_a = .0;
			for(int l = -hw; l <= hw; l++){ // filtering process
				for(int k = -hw; k <= hw; k++){
          int hgt=j+l;
          int wid=i+k;
          
          //edge 
          if(hgt<0)hgt=0;if(hgt>=img.height)hgt=img.height-1;
          if(wid<0)wid=0;if(wid>=img.width)wid=img.width-1;

					int p = hgt*img.width + wid;
					sum_r += f[l + hw][k + hw] * red(img.pixels[p]);
					sum_g += f[l + hw][k + hw] * green(img.pixels[p]);
					sum_b += f[l + hw][k + hw] * blue(img.pixels[p]);
          sum_a += f[l + hw][k + hw] * alpha(img.pixels[p]);//add alpha
				}
			}
      filteredImg.pixels[j * img.width + i] = color(sum_r, sum_g, sum_b, sum_a);
		}
	}
	filteredImg.updatePixels();
	return(filteredImg);
}

color bilateral(PImage img,int px,int py,float s1,float s2) {//target pixel:(px,py) sigma1:s1 sigma2:s2
	//bilateral filter
	int hw=filter_width/2;
  float sum_r=.0,sum_g=.0,sum_b=.0,sum_a=.0;// denominator(nomilizer) of each color g(px,py)
	float h_r,h_g,h_b,h_a;//filter of each color
	float g_r=.0,g_g=.0,g_b=.0,g_a=.0;//calculation result of each color

	color c1=img.pixels[py*img.width+px],c2;
	float exp1;

	//calculate denominator
	for(int j = -hw; j <= hw; j++){
		for(int i = -hw; i <= hw; i++){
      int hgt=j+py;
      int wid=i+px;
      //edge 
      if(hgt<0)hgt=0;if(hgt>=img.height)hgt=img.height-1;
      if(wid<0)wid=0;if(wid>=img.width)wid=img.width-1;

			c2=img.pixels[hgt*img.width+wid];
			exp1=exp(-(j * j + i * i) / 2. / s1 / s1);
			sum_r+=exp1*exp(-pow(red(c1)-red(c2),2)/2./s2/s2);
			sum_g+=exp1*exp(-pow(green(c1)-green(c2),2)/2./s2/s2);
			sum_b+=exp1*exp(-pow(blue(c1)-blue(c2),2)/2./s2/s2);
      sum_a+=exp1*exp(-pow(alpha(c1)-alpha(c2),2)/2./s2/s2);//add alpha
		}
	}

	//calculate filtered color with normalization
	for(int j = -hw; j <= hw; j++){
		for(int i = -hw; i <= hw; i++){
      int hgt=j+py;
      int wid=i+px;
      //edge 
      if(hgt<0)hgt=0;if(hgt>=img.height)hgt=img.height-1;
      if(wid<0)wid=0;if(wid>=img.width)wid=img.width-1;

			c2=img.pixels[hgt*img.width+wid];
			exp1=exp(-(j * j + i * i) / 2. / s1 / s1);
			h_r=exp1*exp(-pow(red(c1)-red(c2),2)/2./s2/s2);
			h_g=exp1*exp(-pow(green(c1)-green(c2),2)/2./s2/s2);
			h_b=exp1*exp(-pow(blue(c1)-blue(c2),2)/2./s2/s2);
      h_a=exp1*exp(-pow(alpha(c1)-alpha(c2),2)/2./s2/s2);

			g_r+=h_r/sum_r*red(c2);
			g_g+=h_g/sum_g*green(c2);
			g_b+=h_b/sum_b*blue(c2);
      g_a+=h_b/sum_b*alpha(c2);

		}
	}
	return color(g_r,g_g,g_b,g_a);
}

PImage bilateral_filtering(PImage img, float s1,float s2){
	PImage filteredImg = createImage(img.width, img.height, ALPHA);
	img.loadPixels();
	filteredImg.loadPixels();
	for(int j = 0; j < img.height; j++){
		for(int i = 0; i < img.width; i++){
			filteredImg.pixels[j * img.width + i] = bilateral(img,i,j,s1,s2);
		}
	}
	filteredImg.updatePixels();
	return(filteredImg);
}

PImage mosaic(PImage img, int w){
	PImage filteredImg = createImage(img.width, img.height, ALPHA);
	img.loadPixels();
	for(int j = 0; j < img.height / w * w; j += w){    // process until w *n pixels.
		for(int i = 0; i < img.width / w * w; i += w){ // (int) / (int) = (int)
			float sum_r = .0, sum_g = .0, sum_b = .0, sum_a = .0;
			for(int l = 0; l < w; l++){ // calculate average of w x w pixels
				for(int k = 0; k < w; k++){
					int p = (j + l) * img.width + i + k;
					sum_r += red(img.pixels[p]);
					sum_g += green(img.pixels[p]);
					sum_b += blue(img.pixels[p]);
          sum_a += alpha(img.pixels[p]);
				}
			}
			sum_r /= (w * w); sum_g /= (w * w);	sum_b /= (w * w); sum_a /= (w * w);
			for(int l = 0; l < w; l++)
				for(int k = 0; k < w; k++) // save filtered image
					filteredImg.pixels[(j + l) * img.width + (i + k)] = color(sum_r, sum_g, sum_b,sum_a);
		}
	}
	filteredImg.updatePixels();
	return filteredImg;
}

//reference:http://30min-processing.hatenablog.com/entry/2015/12/01/000000
PImage unsharp(PImage img, int w){
  int hw = w/2;
  PImage filteredImg = createImage(img.width, img.height, ALPHA);
  float intensity = 10.0;
  
  color[][] blurImage = new color[img.width][img.height];
  img.loadPixels();
  for(int x = 0; x < img.width; x++){
    for(int y = 0; y < img.height; y++){
      float r = 0, g = 0, b = 0;
      for(int u = x - hw; u <= x + hw; u++){
        for(int v = y - hw; v <= y + hw; v++){
          int hgt=v;
          int wid=u;
          //edge 
          if(hgt<0)hgt=0;if(hgt>=img.height)hgt=img.height-1;
          if(wid<0)wid=0;if(wid>=img.width)wid=img.width-1;

          color c = img.pixels[hgt * img.width + wid];
          r += red(c);
          g += green(c);
          b += blue(c);
        }
      }
      r /= float(w) * w;
      g /= float(w) * w;
      b /= float(w) * w;
      blurImage[x][y] = color(r, g, b);
      
    }
  }
    
  for(int x = 0; x < img.width; x++){
    for(int y = 0; y < img.height; y++){
      color c = img.pixels[y * img.width + x];
      color blur = blurImage[x][y];
      float variantR = (red(c) - red(blur)) * intensity;
      float variantG = (green(c) - green(blur)) * intensity;
      float variantB = (blue(c) - blue(blur)) * intensity;
      filteredImg.pixels[y * img.width + x] = color(red(c) + variantR, green(c) + variantG, blue(c) + variantB);
    }
  }
  
  filteredImg.updatePixels();
  return filteredImg;
}
