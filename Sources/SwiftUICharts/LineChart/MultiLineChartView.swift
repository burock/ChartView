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
    public var opacity: [Double]?
    public var fillGradient: Gradient?
    public var style: ChartStyle
    public var darkModeStyle: ChartStyle
    public var formSize: CGSize
    public var dropShadow: Bool
    public var valueSpecifier:String
    public var curvedLines: [Bool]
    public var lineWidth: [Int]
    public var displayZero: Bool? = false
    var zeros: [Double]?
    
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
                opacity: [Double] = [1.0, 1.0],
                fillGradient: Gradient?,
                curvedLines: [Bool] = [true,true],
                lineWidth: [Int] = [3,3],
                displayZero: Bool?,
                valueSpecifier: String = "%.1f") {
        
        self.data = data.map({ MultiLineChartData(points: $0.0, gradient: $0.1)})
        self.displayZero = displayZero
        self.title = title
        self.labels = labels
        self.showBackground = showBackground
        self.names = names
        self.legend = legend
        self.fillGradient = fillGradient
        self.style = style
        self.darkModeStyle = style.darkModeStyle != nil ? style.darkModeStyle! : Styles.lineViewDarkMode
        self.formSize = form
        frame = CGSize(width: self.formSize.width, height: self.formSize.height/2)
        self.rateValue = rateValue
        self.dropShadow = dropShadow
        self.valueSpecifier = valueSpecifier
        self.curvedLines = curvedLines
        self.lineWidth = lineWidth
        self.opacity = opacity
        let min = abs(globalMin(0))
        self.zeros = [Double](repeating: min, count: self.data[0].onlyPoints().count)
        print(zeros?.description)
    }
    
    public var body: some View {
        ZStack(alignment: .top){
            RoundedRectangle(cornerRadius: 10)
                .fill(self.colorScheme == .dark ? self.darkModeStyle.backgroundColor : self.style.backgroundColor)
                .frame(width: frame.width, height: 240, alignment: .center)
                .shadow(radius: self.dropShadow ? 8 : 0)
            VStack(alignment: .leading){
                if(!self.showIndicatorDot){
                    VStack(alignment: .leading, spacing: 8){
                        Text(self.title ?? "")
                            .font(.body)
                            .bold()
                            .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.textColor : Color.gray)
                    }
                    .transition(.opacity)
                    .animation(.easeIn(duration: 0.3))
                    .padding([.leading, .top])
                }else{
                    HStack{
                        Spacer()
                        Text("\(names?[0] ?? "") \(self.currentValue, specifier: self.valueSpecifier)")
                            .font(.subheadline).foregroundColor(self.data[0].getGradient().end)
                            .offset(x: 0, y: 10)
                        Text("\(names?[1] ?? "") \(self.currentValue2, specifier: self.valueSpecifier)")
                            .font(.subheadline).foregroundColor(self.data[1].getGradient().end)
                            .offset(x: 0, y: 10)
                        Text("@\(self.currentLabel)").font(.subheadline)
                            .foregroundColor(.gray)
                            .offset(x: 0, y: 10)
                        Spacer()
                    }
                    .transition(.scale)
                }
                
                GeometryReader{ geometry in
                    ZStack{
                        GeometryReader{ reader in
                            Rectangle()
                                .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.backgroundColor : self.style.backgroundColor)
                            ForEach(0..<self.data.count) { i in
                                if lineWidth[i] > 0 {
                                    Line(data: self.data[i],
                                         //frame: .constant(geometry.frame(in: .local)),
                                         frame: .constant(CGRect(x: 0, y: 0, width: reader.frame(in: .local).width - 30, height: reader.frame(in: .local).height)),
                                         touchLocation: self.$touchLocation,
                                         showIndicator: self.$showIndicatorDot,
                                         minDataValue: .constant(self.globalMin(i)),
                                         maxDataValue: .constant(self.globalMax(i)),
                                         showBackground: showBackground?[i] ?? false,
                                         fillGradient: fillGradient,
                                         curvedLines: curvedLines[i],
                                         lineWidth: lineWidth[i],
                                         gradient: self.data[i].getGradient(),
                                         index: i).opacity(self.opacity?[i] ?? 0.8)
                                } else {
                                    BarChartRow(data: self.data[i].onlyPoints(),
                                                accentColor: self.data[i].getGradient().end,
                                                gradient: self.data[i].getGradient(),
                                                touchLocation: $touchLocation.y).opacity(self.opacity?[i] ?? 0.8)
                                }
                            }
                            if displayZero ?? false {
                                Line(data: ChartData(points: zeros ?? [5]),
                                     frame: .constant(geometry.frame(in: .local)),
                                     touchLocation: self.$touchLocation,
                                     showIndicator: self.$showIndicatorDot,
                                     minDataValue: .constant(0),
                                     maxDataValue: .constant(self.globalMax(0)),
                                     showBackground: false,
                                     fillGradient: fillGradient,
                                     curvedLines: false,
                                     lineWidth: 1,
                                     gradient: GradientColors.orange,//self.data[0].getGradient(),
                                     index: 0).opacity(self.opacity?[0] ?? 0.8)
                            }
                        }
                    }
                }
                .frame(width: frame.width, height: frame.height + 30)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .offset(x: 0, y: 0)
                
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
                               , title: "Line chart", legend: "Basic", fillGradient: nil, displayZero: false)
                .environment(\.colorScheme, .light)
        }
    }
}
