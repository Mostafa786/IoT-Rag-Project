// import 'dart:nativewrappers/_internal/vm/lib/mirrors_patch.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NaturalLanguagePage extends StatefulWidget {
  const NaturalLanguagePage({super.key});

  @override
  State<NaturalLanguagePage> createState() => _NaturalLanguagePageState();
}

class _NaturalLanguagePageState extends State<NaturalLanguagePage> {
  ScrollController scrollController = ScrollController();
  TextEditingController message = TextEditingController();
  bool isResponse = false;
  List userMessage = [];
  List responseMessage = [];
  String theUserMessage = "";
  String theResponseMessage = "";
  // http.Request? request;
  http.StreamedResponse? response;
  List<Map> chat = [
    {"الدور": "المستخدم", "المحتوي": ""},
  ];
  // Map replaces = {
  //   "0":"٠",
  //   "1":"١",
  //   "2":"٢",
  //   "3":"٣",
  //   "4":"٤",
  //   "5":"٥",
  //   "6":"٦",
  //   "7":"٧",
  //   "8":"٨",
  //   "9":"٩",
  //   };
    
  answerOfAi()async{
    final request = http.MultipartRequest("POST",Uri.parse("https://lithoid-nonrigid-yasuko.ngrok-free.dev/Ask"));
    // request.headers['Content-Type'] = 'application/';
    
    request.fields["query_question"] = theUserMessage;
    
    response = await request.send();
    response!.stream.transform(utf8.decoder).listen((chunk){
      setState(() {
        theResponseMessage = theResponseMessage + chunk;
        theResponseMessage = theResponseMessage.replaceAll("**", "");
        // for(int i = 0;i<replaces.length;i++){
        // theResponseMessage = theResponseMessage.replaceAll(replaces.keys.elementAt(i), replaces.values.elementAtOrNull(i));
        // }
        responseMessage[responseMessage.length-1] = theResponseMessage;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async{
    await scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: Duration(seconds: 2),
      curve: Curves.easeOut,
    );
  });
      },onError: (error) {
        throw("Error: $error");
      },
    );
   
  }
  sendMessage()async{
    message.text = "";
    userMessage.add(theUserMessage);
    responseMessage.add("");
    setState(() {
      
    });
    await answerOfAi();
    theUserMessage = "";
    theResponseMessage = "";
    
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      // appBar: AppBar(backgroundColor: Colors.deepOrange,centerTitle: true,title: Text("Chatbot for IoT"),foregroundColor: Colors.white,),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(controller:scrollController,itemCount: userMessage.length,physics: BouncingScrollPhysics(),itemBuilder: (context, index) {
            if (userMessage[index] != ""){
            return Column(children:[Align(
              alignment: Alignment.topRight,
              child: ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              child:Container(margin:EdgeInsets.only(top: 10,right: 10),padding: EdgeInsets.all(10),decoration:BoxDecoration(borderRadius: BorderRadius.circular(10),color:Colors.deepOrange),
              child:Text(userMessage[index],textAlign: TextAlign.right))),
            ),responseMessage[index] != ""?Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              child:Container(margin:EdgeInsets.only(top: 10,left: 10),padding: EdgeInsets.all(10),decoration:BoxDecoration(borderRadius: BorderRadius.circular(10),color:Colors.grey),
              child:Text(responseMessage[index],textAlign: TextAlign.right))),
            ):Container()
            ]);}

            return SizedBox.shrink();
          },
          ),
        ),
        Container(margin: EdgeInsets.symmetric(vertical: 5,horizontal: 10),
        padding: EdgeInsets.only(bottom: 25),
              child: Row(mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: TextField(maxLines: null,textInputAction: TextInputAction.newline,keyboardType: TextInputType.multiline,controller: message,enabled: !isResponse,decoration: InputDecoration(hintText:"Any question about IoT?",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))),onChanged: (value){
                        setState(() {
                        theUserMessage = value;
                        });
                      },),
                  ),
                  Container(margin: EdgeInsets.only(left: 5),decoration: ShapeDecoration(color: theUserMessage.isEmpty?Colors.grey:Colors.deepOrange,shape: CircleBorder()),
                     child: Container(margin: EdgeInsets.only(left: 3.5) ,child: IconButton(onPressed:theUserMessage.isNotEmpty?sendMessage:null, icon: Icon(Icons.send_rounded,color: Colors.black,)))),
                     
                ],
              ),
            ),
      ],
    ),);
  }
}