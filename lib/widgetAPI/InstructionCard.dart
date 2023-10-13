import 'package:flutter/material.dart';

class InstructionCard extends StatefulWidget {
  final int currentIndex;
  final List<Map<String, String>> instructions;
  final VoidCallback goToPreviousInstruction;
  final VoidCallback goToNextInstruction;

  InstructionCard({
    required this.currentIndex,
    required this.instructions,
    required this.goToPreviousInstruction,
    required this.goToNextInstruction,
  });

  @override
  _InstructionCardState createState() => _InstructionCardState();
}

class _InstructionCardState extends State<InstructionCard> {
  double cardHeight = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the card height with the desired initial height.
    cardHeight = MediaQuery.of(context).size.height * 0.2;
  }

  @override
  void didUpdateWidget(covariant InstructionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the card height when the content changes.
    cardHeight = MediaQuery.of(context).size.height * 0.2;
  }

  @override
  Widget build(BuildContext context) {
    String? distanceText;

    if (widget.currentIndex >= 0 &&
        widget.currentIndex < widget.instructions.length) {
      final instruction = widget.instructions[widget.currentIndex];
      final distanceString = instruction["distance"];

      if (distanceString != null) {
        final distanceValue = double.tryParse(distanceString);
        if (distanceValue != null) {
          final formattedDistance = distanceValue.toStringAsFixed(0);
          distanceText = '$formattedDistance m';
        }
      }
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 300), // You can adjust the duration
      height: cardHeight,
      child: Card(
        margin: EdgeInsets.only(top: 30.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        color: Colors.blue,
        elevation: 4,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FloatingActionButton(
                  onPressed: widget.goToPreviousInstruction,
                  tooltip: 'Previous',
                  backgroundColor: Colors.black,
                  mini: true,
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.currentIndex >= 0 &&
                        widget.currentIndex < widget.instructions.length)
                      Text(
                        widget.instructions[widget.currentIndex]["text"] ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    SizedBox(height: 5.0),
                    if (distanceText != null)
                      Text(
                        distanceText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      )
                    else
                      Text(
                        'No instructions available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FloatingActionButton(
                  onPressed: widget.goToNextInstruction,
                  tooltip: 'Next',
                  backgroundColor: Colors.black,
                  mini: true,
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
