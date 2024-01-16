import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
class HomePage extends StatelessWidget {
  var height,width;

  List imgData = [
    "images/data.jpg",
    "images/budget.jpg",
    "images/hist.jpg",
    "images/rec.jpg",
    "images/usage.jpg",
    "images/about.jpg",
  ];
  List titles = [
    "Sensors Data",
    "Budget Management",
    "Historical Data",
    "Recommendations",
    "Check Usage",
    "About",
  ];
  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: Colors.indigo,
         // height: height,
          width: width,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.indigo,

                             ),
                    height: height * 0.25,
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: 35,
                            left: 20,
                            right: 20,

                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                            InkWell(
                              onTap: (){},
                              child: Icon(Icons.sort, color: Colors.white,
                              size: 40,
                              ),
                            ),
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white,
                                image: DecorationImage(
                                  image: AssetImage("images/logo.png",)
                                ),
                              ),

                            )
                          ],),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: 20,
                            left: 30,

                        ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Welcome",
                              style: TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                              ),
                              SizedBox(
                                height: 10,
                              ),

                              Text("To the smartE App",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white54,
                                  letterSpacing: 0,
                                ),),
                            ],
                          ),
                        )
                      ],
                    ),
                    ),
                    SingleChildScrollView(
                      child: Container(
                      decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),

                          ),
                     // height: height * 0.75,
                      width: width,
                        child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          mainAxisSpacing: 25,
                        ),


                      shrinkWrap: true,


                        physics: NeverScrollableScrollPhysics(),
                        itemCount: imgData.length,
                        itemBuilder: (context, index){
                          return InkWell(
                            onTap: (){},
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Image.asset(imgData[index],
                                  width: 100,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },

                      ),
                                         ),
                    ),
              ],
            ),
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Home"),
        actions: [IconButton(onPressed: () async {
         await FirebaseAuth.instance.signOut();
        },
          icon: const Icon(Icons.login),
        ),
        ],

    ),


    );
  }
}