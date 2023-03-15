//
//  AddVcrView.swift
//  demoshift
//
//  Created by Александр Иванов on 02.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct AddVcrView: View {
    @Environment(\.interactorsContainer) var interactorsContainer: InteractorsContainer
    @EnvironmentObject var state: AddVcrState
    private let colorTimeHelper = ColorHelper()

    var body: some View {
        VStack {
            Text("Добавление считывателя")
                .font(.headline)
            Spacer()
            Text("Отсканируйте QR-код")
            Spacer()
            QrCode(qrCode: Image(uiImage: state.qrCode ?? UIImage(systemName: "qrcode")!))
                .background(ProgressRectangle(state: 1 - state.currentTime / colorTimeHelper.maxTime,
                                              color: colorTimeHelper.getCurrentColor(progress: state.currentTime)))
                .blur(radius: state.isBlurQr ? 3 : 0)
                .padding()
            Spacer()
            Text("время действия QR-кода")
                .padding(.bottom)
            Text(String(format: "%0.2d:%0.2d", Int(state.currentTime) / 60, Int(state.currentTime) % 60))
                .foregroundColor(Color(colorTimeHelper.getCurrentColor(progress: state.currentTime)))
                .font(.system(.title, design: .monospaced))
            Spacer()
            Button(action: {
                interactorsContainer.addVcrInteractor?.loadQrCode()
            }, label: {
                Text("Сгенерировать новый QR-код")
            })
                .buttonStyle(RoundedFilledButton())
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear(perform: {
            interactorsContainer.addVcrInteractor?.willAppear(maxTime: colorTimeHelper.maxTime)
        })
        .onDisappear(perform: {
            interactorsContainer.addVcrInteractor?.willDisappear()
        })
    }
}

private struct ColorHelper {
    private struct TransitionColor {
        let time: CGFloat
        let fromColor: UIColor?
        let toColor: UIColor?
    }

    let greenColor = UIColor(named: "text-blue")
    let yellowColor = UIColor(named: "text-yellow")
    let redColor = UIColor(named: "text-red")
    private let colors: [TransitionColor]

    private let transitionTime: CGFloat = 5
    private let redTime: CGFloat = 10
    private let yellowTime: CGFloat = 20
    private let greenTime: CGFloat
    let maxTime: CGFloat = 120

    init() {
        self.greenTime = maxTime - 2 * transitionTime - redTime - yellowTime
        assert(greenTime > 0.0)
        self.colors = [TransitionColor(time: redTime,
                                      fromColor: redColor,
                                      toColor: nil),
                      TransitionColor(time: transitionTime,
                                      fromColor: yellowColor,
                                      toColor: redColor),
                      TransitionColor(time: yellowTime,
                                      fromColor: yellowColor,
                                      toColor: nil),
                      TransitionColor(time: transitionTime,
                                      fromColor: greenColor,
                                      toColor: yellowColor),
                      TransitionColor(time: greenTime,
                                      fromColor: greenColor,
                                      toColor: nil)]
    }

    private func getTransitionColor(_ transitionColor: TransitionColor, transitionPhase: CGFloat) -> UIColor {
        if let from = transitionColor.fromColor,
           let to = transitionColor.toColor {
            return UIColor(red: from.rgba.red + (to.rgba.red - from.rgba.red) * transitionPhase,
                           green: from.rgba.green + (to.rgba.green - from.rgba.green) * transitionPhase,
                           blue: from.rgba.blue + (to.rgba.blue - from.rgba.blue) * transitionPhase,
                           alpha: from.rgba.alpha + (to.rgba.alpha - from.rgba.alpha) * transitionPhase)
        } else {
            return transitionColor.fromColor ?? UIColor.clear
        }
    }

    func getCurrentColor(progress: CGFloat) -> UIColor {
        var currentInterval = maxTime
        let currentTick = maxTime - progress

        for color in colors {
            currentInterval -= color.time
            if currentTick > currentInterval {
                let phase = (currentTick - currentInterval)/color.time
                return getTransitionColor(color, transitionPhase: phase)
            }
        }
        return UIColor.clear
    }
}

struct RGBa {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat
}

extension UIColor {
    var rgba: RGBa {
        var color = RGBa(red: 0, green: 0, blue: 0, alpha: 0)
        getRed(&color.red, green: &color.green, blue: &color.blue, alpha: &color.alpha)

        return color
    }
}
