void xmlRecorderInit() {
  xmlIO = new XMLInOut(this);
  MotionCapture = new proxml.XMLElement("MotionCapture");
  MotionCapture.addAttribute("fps", fps);
  MotionCapture.addAttribute("width", sW);
  MotionCapture.addAttribute("height", sH);
  MotionCapture.addAttribute("depth", sD);
  MotionCapture.addAttribute("numFrames", counter);
  MotionCapture.addAttribute("dialogueFile", dialogueFile);
}

//~~~

void xmlRecorderUpdate() {
  background(0);
  //if (modeRec||(modeOsc&&found)) {
  if (modeRec) {
    fill(255, 200);
    stroke(0);
    strokeWeight(5);
    for (int i=0;i<osceletonNames.length;i++) {
      pushMatrix();
      translate(sW*x[i], sH*y[i], (-sD*z[i])+abs(sD/2));
      //~~~~~~~~~~
      //custom joint colors if you need them
      
      if(osceletonNames[i]=="r_hand"){
         fill(255,200,200,200);
      }else{
        fill(255,200);
      }
      
      //~~~~~~~~~~
      ellipse(0, 0, circleSize, circleSize);
      popMatrix();
    }
  } 
  if (countdown.go&&!modeStop) {
    xmlAdd();
    counter++;
  }
  countdown.update();
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/joint") && msg.checkTypetag("sifff")) {
    found = true;
    for (int i=0;i<osceletonNames.length;i++) {
      if (modeOsc&&msg.get(0).stringValue().equals(osceletonNames[i])) {
        x[i] = msg.get(2).floatValue();
        y[i] = msg.get(3).floatValue();
        z[i] = msg.get(4).floatValue();
      }
    }
  }
}


void simpleOpenNiEvent(int userId) {
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, simpleOpenNiPos[0]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_NECK, simpleOpenNiPos[1]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_TORSO, simpleOpenNiPos[2]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, simpleOpenNiPos[3]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, simpleOpenNiPos[4]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HAND, simpleOpenNiPos[5]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, simpleOpenNiPos[6]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, simpleOpenNiPos[7]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND, simpleOpenNiPos[8]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HIP, simpleOpenNiPos[9]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, simpleOpenNiPos[10]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_FOOT, simpleOpenNiPos[11]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HIP, simpleOpenNiPos[12]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_KNEE, simpleOpenNiPos[13]);
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_FOOT, simpleOpenNiPos[14]);

  for (int i=0;i<osceletonNames.length;i++) {
    context.convertRealWorldToProjective(simpleOpenNiPos[i], simpleOpenNiPos_proj[i]);
    x[i] = simpleOpenNiPos_proj[i].x/sW;
    y[i] = simpleOpenNiPos_proj[i].y/sH;
    z[i] = simpleOpenNiPos_proj[i].z/(sD*10); //approximate 'cause don't know real SimpleOpenNI depth max/min in pixels; will fix
  }
}

void xmlAdd() {
  MotionCapture.addAttribute("numFrames", counter);
  proxml.XMLElement MocapFrame = new proxml.XMLElement("MocapFrame");
  MotionCapture.addChild(MocapFrame);
  MocapFrame.addAttribute("index", counter);
  proxml.XMLElement Skeleton = new proxml.XMLElement("Skeleton");
  MocapFrame.addChild(Skeleton);
  Skeleton.addAttribute("id", 0);
  proxml.XMLElement Joints = new proxml.XMLElement("Joints");
  Skeleton.addChild(Joints);
  for (int i=0;i<osceletonNames.length;i++) {
    oscXmlTags[i] = new proxml.XMLElement(osceletonNames[i]);
    Joints.addChild(oscXmlTags[i]);
    if (""+x[i]=="NaN"||""+y[i]=="NaN"||""+z[i]=="NaN") {
      oscXmlTags[i].addAttribute("x", 0.0);
      oscXmlTags[i].addAttribute("y", 0.0);
      oscXmlTags[i].addAttribute("z", 0.0);
    }
    else {
      oscXmlTags[i].addAttribute("x", x[i]);
      oscXmlTags[i].addAttribute("y", y[i]);
      oscXmlTags[i].addAttribute("z", z[i]);
    }
  }
}


//exports xml file with all original data
void xmlSaveToDisk() {
  xmlIO.saveElement(MotionCapture, xmlFilePath + "/" + xmlFileName + (masterFileCounter) + "." + xmlFileType);
}

//exports puppet pins as text with only x and y
void aePinSaveToDisk(int mfc) {
  for (int z=0;z<mfc;z++) {
    int zz=z+1;
    xmlPlayerInit(zz);
    if (loaded) {
      for (int i=0;i<pinNums.length;i++) {
        pinNums[i] = i+1;
      }
      data = new Data();
      data.beginSave();
      data.add("Adobe After Effects 8.0 Keyframe Data");
      data.add("\r");
      data.add("\t"+"Units Per Second"+"\t"+fps);
      data.add("\t"+"Source Width"+"\t"+sW);
      data.add("\t"+"Source Height"+"\t"+sH);
      data.add("\t"+"Source Pixel Aspect Ratio"+"\t"+"1");
      data.add("\t"+"Comp Pixel Aspect Ratio"+"\t"+"1");
      for (int j=0;j<osceletonNames.length;j++) {
        modesRefresh();
        data.add("\r");
        data.add("Effects" + "\t" + "Puppet #2" + "\t" + "arap #3" + "\t" + "Mesh" + "\t" + "Mesh #1" + "\t" + "Deform" + "\t" + "Pin #" + pinNums[j] + "\t" + "Position");
        data.add("\t" + "Frame" + "\t" + "X pixels" + "\t" + "Y pixels");
        for (int i=0;i<MotionCapture.countChildren();i++) { 
          try{
            data.add("\t" + i  
              + "\t" + (sW * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("x")))
              + "\t" + (sH * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("y")))); //gets to the child we need //gets to the child we need
          }catch(Exception e){ }
        }
      }
      data.add("\r");
      data.add("\r");
      data.add("End of Keyframe Data");
      data.endSave("data/"+ aeFilePath + "/" + aeFileName + zz +"."+aeFileType);
    }
  }
}

//export 2D points as text with xy
void aePointSaveToDisk(int mfc) {
  for (int z=0;z<mfc;z++) {
    int zz=z+1;
    xmlPlayerInit(zz);
    if (loaded) {
      for (int i=0;i<pinNums.length;i++) {
        pinNums[i] = i+1;
      }
      data = new Data();
      data.beginSave();
      data.add("Adobe After Effects 8.0 Keyframe Data");
      data.add("\r");
      data.add("\t"+"Units Per Second"+"\t"+fps);
      data.add("\t"+"Source Width"+"\t"+sW);
      data.add("\t"+"Source Height"+"\t"+sH);
      data.add("\t"+"Source Pixel Aspect Ratio"+"\t"+"1");
      data.add("\t"+"Comp Pixel Aspect Ratio"+"\t"+"1");
      for (int j=0;j<osceletonNames.length;j++) {
        modesRefresh();
        data.add("\r");
        data.add("Effects" + "\t" + "Point Control #" + pinNums[j] + "\t" + "Point #2");
        data.add("\t" + "Frame" + "\t" + "X pixels" + "\t" + "Y pixels");
        for (int i=0;i<MotionCapture.countChildren();i++) { 
          try{
            data.add("\t" + i  
              + "\t" + (sW * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("x")))
              + "\t" + (sH * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("y")))); //gets to the child we need //gets to the child we need
          }catch(Exception e){ }
        }
      }
      data.add("\r");
      data.add("\r");
      data.add("End of Keyframe Data");
      data.endSave("data/"+ aePointFilePath + "/" + aePointFileName + zz +"."+aePointFileType);
    }
  }
}

//export 3D points as text with xyz
void aePoint3DsaveToDisk(int mfc) {
  for (int z=0;z<mfc;z++) {
    int zz=z+1;
    xmlPlayerInit(zz);
    if (loaded) {
      for (int i=0;i<pinNums.length;i++) {
        pinNums[i] = i+1;
      }
      data = new Data();
      data.beginSave();
      data.add("Adobe After Effects 8.0 Keyframe Data");
      data.add("\r");
      data.add("\t"+"Units Per Second"+"\t"+fps);
      data.add("\t"+"Source Width"+"\t"+sW);
      data.add("\t"+"Source Height"+"\t"+sH);
      data.add("\t"+"Source Pixel Aspect Ratio"+"\t"+"1");
      data.add("\t"+"Comp Pixel Aspect Ratio"+"\t"+"1");
      for (int j=0;j<osceletonNames.length;j++) {
        modesRefresh();
        data.add("\r");
        data.add("Effects" + "\t" + "3D Point Control #" + pinNums[j] + "\t" + "3D Point #2");
        data.add("\t" + "Frame" + "\t" + "X pixels" + "\t" + "Y pixels" + "\t" + "Z pixels");
        for (int i=0;i<MotionCapture.countChildren();i++) { 
          try{
            data.add("\t" + i  
              + "\t" + (sW * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("x")))
              + "\t" + (sH * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("y"))) //gets to the child we need //gets to the child we need
            + "\t" + (100 * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("z")))); //gets to the child we need //gets to the child we need
          }catch(Exception e){ }
        }
      }
      data.add("\r");
      data.add("\r");
      data.add("End of Keyframe Data");
      data.endSave("data/"+ aePoint3DFilePath + "/" + aePoint3DFileName + zz +"."+aePoint3DFileType);
    }
  }
}

//export JavaScript script to automate rigging tasks
void aeJsxSaveToDisk(int mfc) {
  for (int z=0;z<mfc;z++) {
    int zz=z+1;
    xmlPlayerInit(zz);
    if (loaded) {
      for (int i=0;i<pinNums.length;i++) {
        pinNums[i] = i+1;
      }
      AEkeysBegin();
      data.add("\t" + "var mocap = myComp.layers.addSolid([0, 0, 0], \"mocap\", 640, 480, 1);" + "\r");
      data.add("\t" + "mocap.guideLayer = true;" + "\r");
      data.add("\t" + "mocap.locked = true;" + "\r");
      data.add("\t" + "mocap.property(\"position\").setValue([320,240]);" + "\r");
      data.add("\t" + "mocap.property(\"opacity\").setValue(0);" + "\r");
      for (int j=0;j<osceletonNames.length;j++) {
        modesRefresh();
        data.add("\r");
        data.add("\t" + "var myEffect = mocap.property(\"Effects\").addProperty(\"3D Point Control\");" + "\r");
        data.add("\t" + "myEffect.name = \"" + osceletonNames[j] + "\";" + "\r");
        //(\"Blurriness\").setValue(61);");
        //data.add("\t" + "var solid = myComp.layers.addSolid([1.0, 1.0, 0], \"" + osceletonNames[j] + "\", 50, 50, 1);" + "\r");
        /*
        if (motionBlur) {
         data.add("\t" + "solid.motionBlur = true;" + "\r");
         }
         if (applyEffects) {
         AEeffects();
         }
         */
        //data.add("\r");
        data.add("\t" + "var p = mocap.property(\"Effects\")(\"" + osceletonNames[j] + "\")(\"3D Point\");" + "\r");
        data.add("p.expression = \"\"\"smooth(.2,5)\"\"\";");
        //data.add("\t" + "var r = solid.property(\"rotation\");" + "\r");
        //data.add("\r");
        for (int i=0;i<MotionCapture.countChildren();i++) { 
          try{
            PVector temp = new PVector(0, 0, 0);
            temp.x = (sW * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("x")));
            temp.y = (sH * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("y")));
            temp.z = (100* float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("z")));
            data.add("\t\t" + "p.setValueAtTime(" + AEkeyTime(i, MotionCapture.countChildren()) + ", [" + temp.x + ", " + temp.y + ", " + temp.z + "]);" + "\r");
          }catch(Exception e){ }
        }

        data.add("\t" + "var solid = myComp.layers.addSolid([1.0, 0, 0], \"" + osceletonNames[j] + "\", 50, 50, 1);" + "\r");
        data.add("\t" + "solid.guideLayer = true;" + "\r");
        data.add("\t" + "solid.property(\"opacity\").setValue(33);" + "\r");
        data.add("\t" + "var p = solid.property(\"position\");" + "\r");
        data.add("\t" + "var expression = " + "\r");
        data.add("\t" + "//~~~~~~~~~~~~~expression here~~~~~~~~~~~~~~~" + "\r");
        data.add("\t\t" + "\"" + "var sW = 640;" + "\"" + " +" + "\r");
        data.add("\t\t" + "\"" + "var sH = 480;" + "\"" + " +" + "\r");
        data.add("\t\t" + "\"" + "var dW = thisComp.width;" + "\"" + " +" + "\r");
        data.add("\t\t" + "\"" + "var dH = thisComp.height;" + "\"" + " +" + "\r");
        data.add("\t\t" + "\"" + "var x = fromComp(thisComp.layer(" + "\\" + "\"mocap" + "\\" + "\").effect(" + "\\" + "\"" + osceletonNames[j] + "\\" + "\")(" + "\\" + "\"3D Point" + "\\" + "\"))[0];" + "\"" + " +" + "\r");
        data.add("\t\t" + "\"" + "var y = fromComp(thisComp.layer(" + "\\" + "\"mocap" + "\\" + "\").effect(" + "\\" + "\"" + osceletonNames[j] + "\\" + "\")(" + "\\" + "\"3D Point" + "\\" + "\"))[1];" + "\"" + " +" + "\r");
        data.add("\t\t" + "\"" + "[(1.5 * dW) + (x*(dW/sW)),dH + (y*(dH/sH))];" + "\"" + ";" + "\r");
        data.add("\t" + "//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" + "\r");
        data.add("\t" + "p.expression = expression;");

        /*
        data.add("\r");
         
         data.add("\t" + "var solid = myComp.layers.addSolid([0, 1.0, 0], \"dest_" + osceletonNames[j] + "\", 50, 50, 1);" + "\r");
         data.add("\t" + "var p = solid.property(\"position\");" + "\r");
         data.add("\t" + "var expression = " + "\r");
         data.add("\t" + "//~~~~~~~~~~~~~expression here~~~~~~~~~~~~~~~" + "\r");
         data.add("\t\t" + "\"" + "var nullTarget = " + "\\" + "\"source_" + osceletonNames[j] + "\\" + "\";" + "\"" + " +" + "\r");
         data.add("\t\t" + "\"" + "fromComp(thisComp.layer(nullTarget).transform.position);" + "\";" + "\r");
         data.add("\t" + "//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" + "\r");
         data.add("\t" + "p.expression = expression;");
         */
      }
      AEkeysEnd(zz);
    }
  }
}

void mayaSaveToDisk(int mfc) {
  for (int z=0;z<mfc;z++) {
    int zz=z+1;
    xmlPlayerInit(zz);
    if (loaded) {
      for (int i=0;i<pinNums.length;i++) {
        pinNums[i] = i+1;
      }
      mayaKeysBegin();
       for (int j=0;j<osceletonNames.length;j++) {
        modesRefresh();
       for (int i=0;i<MotionCapture.countChildren();i++) { 
          try{
            PVector temp = new PVector(0, 0, 0);
            temp.x = (10 * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("x")));
            temp.y = (10 * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("y")));
            temp.z = (10 * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("z")));
            data.add("polyCube()" + "\r");
       data.add("currentTime("+i+")"+"\r");
       data.add("move(" + (temp.x) + ", " + (temp.y) + "," + (temp.z) + ")" + "\r");
       data.add("setKeyframe()" + "\r");          
        }catch(Exception e){ }
        }
      }
      mayaKeysEnd(zz);
    }
  }
}

/*
//json parser by Greg Borenstein, gregborenstein.com 
 String toJson() {
 String result = "{\"project\" : \"skelestreamer\",";      
 result += "\"session\" : \"" + uuid + "\",";       
 result += "\"head\" : {\"x\":" + head.x + ", \"y\":" + head.y + ",\"z\":" + head.z + "},";         
 result += "\"neck\" : {\"x\":" + neck.x + ", \"y\":" + neck.y + ",\"z\":" + neck.z + "},";          
 result += "\"rightShoulder\" : {\"x\":" + rightShoulder.x + ", \"y\":" + rightShoulder.y + ",\"z\":" + rightShoulder.z + "},"; 
 result += "\"rightElbow\" : {\"x\":" + rightElbow.x + ", \"y\":" + rightElbow.y + ",\"z\":" + rightElbow.z + "},";    
 result += "\"rightHand\" : {\"x\":" + rightHand.x + ", \"y\":" + rightHand.y + ",\"z\":" + rightHand.z + "},";     
 result += "\"leftShoulder\" : {\"x\":" + leftShoulder.x + ", \"y\":" + leftShoulder.y + ",\"z\":" + leftShoulder.z + "},";  
 result += "\"leftElbow\" : {\"x\":" + leftElbow.x + ", \"y\":" + leftElbow.y + ",\"z\":" + leftElbow.z + "},";     
 result += "\"leftHand\" : {\"x\":" + leftHand.x + ", \"y\":" + leftHand.y + ",\"z\":" + leftHand.z + "},";    
 result += "\"torso\" : {\"x\":" + torso.x + ", \"y\":" + torso.y + ",\"z\":" + torso.z + "},";         
 result += "\"rightHip\" : {\"x\":" + rightHip.x + ", \"y\":" + rightHip.y + ",\"z\":" + rightHip.z + "},";      
 result += "\"rightKnee\" : {\"x\":" + rightKnee.x + ", \"y\":" + rightKnee.y + ",\"z\":" + rightKnee.z + "},";     
 result += "\"rightFoot\" : {\"x\":" + rightFoot.x + ", \"y\":" + rightFoot.y + ",\"z\":" + rightFoot.z + "},";     
 result += "\"leftHip\" : {\"x\":" + leftHip.x + ", \"y\":" + leftHip.y + ",\"z\":" + leftHip.z + "},";       
 result += "\"leftKnee\" : {\"x\":" + leftKnee.x + ", \"y\":" + leftKnee.y + ",\"z\":" + leftKnee.z + "},";     
 result += "\"leftFoot\" : {\"x\":" + leftFoot.x + ", \"y\":" + leftFoot.y + ",\"z\":" + leftFoot.z + "}";     
 
 result += "}";
 return result;
 }
 */

void jsonSaveToDisk(int mfc) {
  for (int z=0;z<mfc;z++) {
    int zz=z+1;
    xmlPlayerInit(zz);
    if (loaded) {
      for (int i=0;i<pinNums.length;i++) {
        pinNums[i] = i+1;
      }
      data = new Data();
      data.beginSave();
      data.add("{"+"\r");
      data.add("\t"+"\"MotionCapture\":{"+"\r");
      try{
        data.add("\t\t"+"\"width\":"+MotionCapture.getAttribute("width")+","+"\r");
        data.add("\t\t"+"\"height\":"+MotionCapture.getAttribute("height")+","+"\r");
        data.add("\t\t"+"\"depth\":"+MotionCapture.getAttribute("depth")+","+"\r");
        data.add("\t\t"+"\"fps\":"+MotionCapture.getAttribute("fps")+","+"\r");
        data.add("\t\t"+"\"numFrames\":"+MotionCapture.getAttribute("numFrames")+","+"\r");
        data.add("\t\t"+"\"dialogueFile\":\""+MotionCapture.getAttribute("dialogueFile")+"\","+"\r");   
      }catch(Exception e){ }
      data.add("\t\t"+"\"MocapFrame\":{"+"\r");
      data.add("\t\t\t"+"\"Skeleton\":["+"\r");
      data.add("\t\t\t\t"+"{"+"\r");
      data.add("\t\t\t\t\t"+"\"Joints\":{"+"\r");
      for (int j=0;j<osceletonNames.length;j++) {
        modesRefresh();
        data.add("\t\t\t\t\t\t"+"\""+osceletonNames[j]+"\":{"+"\r");
        data.add("\t\t\t\t\t\t\t"+"\"name\":\""+osceletonNames[j]+"\","+"\r");
        data.add("\t\t\t\t\t\t\t"+"\"pos\":["+"\r");
        for (int i=0;i<MotionCapture.countChildren();i++) { 
          try{
            if(i==MotionCapture.countChildren()-1){
            data.add("\t\t\t\t\t\t\t\t" + "{"  
              + "\"x\":"+(sW * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("x")))+", "
              + "\"y\":"+(sH * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("y")))+", "
              + "\"z\":"+(sD * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("z")))
              +"}"+"\r"); //gets to the child we need //gets to the child we need
            }else{
            data.add("\t\t\t\t\t\t\t\t" + "{"  
              + "\"x\":"+(sW * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("x")))+", "
              + "\"y\":"+(sH * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("y")))+", "
              + "\"z\":"+(sD * float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("z")))
              +"},"+"\r"); //gets to the child we need //gets to the child we need
            }
          }catch(Exception e){ }
        }
            data.add("\t\t\t\t\t\t\t"+"]"+"\r");        
            if(j==osceletonNames.length-1){
               data.add("\t\t\t\t\t\t"+"}"+"\r");
            }else{
               data.add("\t\t\t\t\t\t"+"},"+"\r");
            }
      }
      data.add("\t\t\t\t\t"+"}"+"\r");
      data.add("\t\t\t\t"+"}"+"\r");
      data.add("\t\t\t"+"]"+"\r");
      data.add("\t\t"+"}"+"\r");
      data.add("\t"+"}"+"\r");
      data.add("}"+"\r");
      data.endSave("data/"+ jsonFilePath + "/" + jsonFileName + zz +"."+jsonFileType);
    }
  }
}

//broken; don't use
boolean errorCheck(int i, int j) {
  if (
    float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("x")) >= 0 &&
    float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("x")) <= 1 &&
    float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("y")) >= 0 &&
    float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("y")) <= 1 &&
    float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("z")) >= 0 &&
    float(MotionCapture.getChild(i).getChild(0).getChild(0).getChild(j).getAttribute("z")) <= 100
    ) {
    return true;
  } else {
    return false;
  }
}

