//
//  File.swift
//  
//
//  Created by Samu András on 2020. 02. 19..
//

import SwiftUI

public struct MultiLineChartView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var data:[MultiLineChartData]
    var labels: [String]
    public var title: String?
    public var legend: String?
    public var names: [String]?
    public var showBackground: [Bool]?
    public var style: ChartStyle
    public var darkModeStyle: ChartStyle
    public var formSize: CGSize
    public var dropShadow: Bool
    public var valueSpecifier:String
    
    @State private var touchLocation:CGPoint = .zero
    @State private var showIndicatorDot: Bool = false
    @State private var currentValue: Double = 2 {
        didSet{
            if (oldValue != self.currentValue && showIndicatorDot) {
                HapticFeedback.playSelection()
            }
            
        }
    }
    @State private var currentValue2: Double = 2 {
        didSet{
            if (oldValue != self.currentValue && showIndicatorDot) {
                HapticFeedback.playSelection()
            }
            
        }
    }
    @State private var currentLabel: String = "" {
        didSet{
            if (oldValue != self.currentLabel && showIndicatorDot) {
                HapticFeedback.playSelection()
            }
            
        }
    }
    
    func globalMin(_ i :Int) -> Double {
        if let min = self.data[i].onlyPoints().compactMap({$0}).min() {
            return min
        }
        return 0
    }
    
    func globalMax(_ i:Int) -> Double {
        if let max = self.data[i].onlyPoints().compactMap({$0}).max() {
            return max
        }
        return 0
    }
    
    var frame = CGSize(width: 180, height: 120)
    private var rateValue: Int?
    
    public init(data: [([Double], GradientColor)],
                labels: [String],
                names: [String],
                title: String,
                legend: String? = nil,
                style: ChartStyle = Styles.lineChartStyleOne,
                form: CGSize = ChartForm.medium,
                rateValue: Int? = nil,
                dropShadow: Bool = true,
                showBackground: [Bool] = [false, false],
                valueSpecifier: String = "%.1f") {
        
        self.data = data.map({ MultiLineChartData(points: $0.0, gradient: $0.1)})
        self.title = title
        self.labels = labels
        self.showBackground = showBackground
        self.names = names
        self.legend = legend
        self.style = style
        self.darkModeStyle = style.darkModeStyle != nil ? style.darkModeStyle! : Styles.lineViewDarkMode
        self.formSize = form
        frame = CGSize(width: self.formSize.width, height: self.formSize.height/2)
        self.rateValue = rateValue
        self.dropShadow = dropShadow
        self.valueSpecifier = valueSpecifier
    }
    
    public var body: some View {
        ZStack(alignment: .center){
            RoundedRectangle(cornerRadius: 10)
                .fill(self.colorScheme == .dark ? self.darkModeStyle.backgroundColor : self.style.backgroundColor)
                .frame(width: frame.width, height: 240, alignment: .center)
                .shadow(radius: self.dropShadow ? 8 : 0)
            VStack(alignment: .leading){
                HStack{
                    Text("\(names?[0] ?? "") \(self.currentValue, specifier: self.valueSpecifier)")
                        .font(.subheadline).foregroundColor(self.data[0].getGradient().end)
                    //.offset(x: 0, y: 30)
                    Text("\(names?[1] ?? "") \(self.currentValue2, specifier: self.valueSpecifier)")
                        .font(.subheadline).foregroundColor(self.data[1].getGradient().end)
                    //.offset(x: 0, y: 30)
                    Text("@\(self.currentLabel)").font(.subheadline)
                        .foregroundColor(.gray)
                    //.offset(x: 0, y: 30)
                    Spacer()
                }
                .transition(.scale)
                GeometryReader{ geometry in
                    ZStack{
                        ForEach(0..<self.data.count) { i in
                            Line(data: self.data[i],
                                 frame: .constant(geometry.frame(in: .local)),
                                 touchLocation: self.$touchLocation,
                                 showIndicator: self.$showIndicatorDot,
                                 minDataValue: .constant(self.globalMin(i)),
                                 maxDataValue: .constant(self.globalMax(i)),
                                 showBackground: showBackground?[i] ?? false,
                                 gradient: self.data[i].getGradient(),
                                 index: i)
                        }
                    }
                }
                .frame(width: frame.width, height: frame.height + 15)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                //.offset(x: 0, y: 0)
            }.frame(width: self.formSize.width, height: self.formSize.height)
        }
        .gesture(DragGesture()
                    .onChanged({ value in
                        self.touchLocation = value.location
                        self.showIndicatorDot = true
                        self.getClosestDataPoint(toPoint: value.location, width:self.frame.width, height: self.frame.height)
                    })
                    .onEnded({ value in
                        self.showIndicatorDot = false
                    })
        )
    }
    
    @discardableResult func getClosestDataPoint(toPoint: CGPoint, width:CGFloat, height: CGFloat) -> CGPoint {
        let points = self.data[0].onlyPoints()
        let points2 = self.data[1].onlyPoints()
        
        let stepWidth: CGFloat = width / CGFloat(points.count-1)
        let stepHeight: CGFloat = height / CGFloat(points.max()! + points.min()!)
        
        let index:Int = Int(round((toPoint.x)/stepWidth))
        if (index >= 0 && index < points.count){
            self.currentValue = points[index]
            self.currentValue2 = points2[index]
            self.currentLabel = self.labels[index]
            
            return CGPoint(x: CGFloat(index)*stepWidth, y: CGFloat(points[index])*stepHeight)
        }
        return .zero
    }
}

struct MultiWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MultiLineChartView(data: [([8,23,54,32,12,37,7,23,43], GradientColors.orange)], labels: 
                                [""], names: []
                               , title: "Line chart", legend: "Basic")
                .environment(\.colorScheme, .light)
        }
    }
}
