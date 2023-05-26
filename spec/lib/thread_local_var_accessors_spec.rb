# frozen_string_literal: true
# domain: PDFs

require 'spec_helper'
require 'thread_local_var_accessors'

class TestTLVAccessors
  include ThreadLocalVarAccessors

  tlv_reader :wait_time1, :wait_time2

  tlv_writer :sleep_time

  tlv_accessor :timeout1, :timeout2

  def set_var(var_name, value)
    tlv_set(var_name, value)
  end
end

TLV = TestTLVAccessors

include ThreadLocalVarAccessors # rubocop:disable Style/MixinUsage
using ThreadLocalVarAccessors::MyRefinements

RSpec.describe ThreadLocalVarAccessors do
  let(:tlv) { TestTLVAccessors.new }

  context 'class methods' do
    let(:test_name) { :a_var_name }

    it 'provides some class methods' do
      expect(TestTLVAccessors).to(
        respond_to(:tlv_reader, :tlv_writer, :tlv_accessor)
      )
    end

    it 'provides some instance methods' do
      expect(TestTLVAccessors.new).to(
        respond_to(:tlv_set, :tlv_set_once, :tlv_get, :tlv_new)
      )
    end

    shared_examples 'tlv_accessor_method' do |method, *ivar_names|
      describe ".#{method}" do
        kind = method.to_s.sub(/^tlv_/, '') # reader, writer, accessor
        reader_kind = %w[reader accessor].include?(kind)
        writer_kind = %w[writer accessor].include?(kind)
        accessor_kind = kind == 'accessor'

        context "Testing #{method}" do
          let(:expected_values) { [42, 43, 44] }

          ivar_names.each do |ivar_name|
            context "with #{ivar_name}" do
              let(:ivar_reader)   { ivar_name }
              let(:ivar_writer)   { "#{ivar_name}=".to_sym }
              let(:current_value) { expected_values.rotate!.first }

              if reader_kind
                context 'with the reader method' do
                  subject { tlv.send(ivar_reader) }

                  it 'creates a reader method' do
                    expect { subject }.to_not raise_error
                  end

                  it 'returns nil when there is no instance value' do
                    expect(subject).to be_nil
                  end

                  it 'returns the instance variable value when invoked' do
                    tlv.tlv_set(ivar_name, current_value)
                    expect(subject).to eq current_value
                  end
                end
              end

              if writer_kind
                context 'with the writer method' do
                  subject { tlv.send(ivar_writer, current_value) }

                  it 'the writer sets the instance variable value when invoked' do
                    tlv.tlv_set(ivar_name, nil)
                    expect(subject).to eq current_value
                    expect(tlv.tlv_get(ivar_name)).to eq current_value
                  end

                  it 'only affects a single instance variable' do
                    subject
                    (ivar_names - [ivar_name]).each do |other_ivar|
                      tlv.tlv_set(other_ivar, 'oops')
                    end
                    expect(tlv.tlv_get(ivar_name)).to eq current_value
                  end
                end
              end

              if accessor_kind
                context 'an accessor generator' do
                  it 'creates both kinds of methods' do
                    expect(tlv).to respond_to(ivar_reader, ivar_writer)
                  end
                end
              end
            end
          end
        end
      end
    end

    it_behaves_like 'tlv_accessor_method', :tlv_reader, :wait_time1, :wait_time2
    it_behaves_like 'tlv_accessor_method', :tlv_writer, :sleep_time
    it_behaves_like 'tlv_accessor_method', :tlv_accessor, :timeout1, :timeout2
  end

  context 'instance methods' do
    let(:ivar_name) { :timeout }
    let(:expected_value) { 42 }
    let(:ivar_value) { tlv.instance_variable_get("@#{ivar_name}".to_sym)&.value }

    describe '.tlv_get' do
      subject { tlv.tlv_get(ivar_name) }

      it "returns the instance variable's value" do
        tlv.tlv_set(ivar_name, expected_value)
        expect(subject).to eq ivar_value
      end

      context 'when there is no instance variable' do
        it { is_expected.to be_nil }
      end
    end

    describe 'tlv_set' do
      shared_examples_for 'tlv_set' do
        it 'returns the value being set' do
          expect(subject).to eq ivar_value
        end

        it 'sets the instance variable of the given name' do
          tlv.instance_variable_set("@#{ivar_name}".to_sym, nil)
          subject
          expect(ivar_value).to eq expected_value
        end
      end

      context 'when given a value' do
        subject { tlv.tlv_set(ivar_name, expected_value) }
        it_behaves_like 'tlv_set'
      end

      context 'when given a block' do
        subject { tlv.tlv_set(ivar_name) { expected_value } }
        it_behaves_like 'tlv_set'
      end
    end

    describe '.tlv_set_once' do
      subject { tlv.tlv_set_once(ivar_name, expected_value) }

      let(:old_value) { 99 }

      shared_examples_for 'tlv_set_once' do
        context 'when the current thread_variable value is nil' do
          it 'sets the ivar' do
            subject
            expect(ivar_value).to eq expected_value
          end

          it 'returns the value' do
            expect(subject).to eq expected_value
          end
        end

        context 'when the current thread_variable is not nil' do
          before { tlv.tlv_set(ivar_name, old_value) }

          it 'does not set the ivar' do
            subject
            expect(ivar_value).to eq old_value
          end

          it 'returns the current value' do
            expect(subject).to eq old_value
          end
        end
      end

      context 'when given a block' do
        subject { tlv.tlv_set_once(ivar_name) { expected_value } }
        it_behaves_like 'tlv_set_once'
      end

      context 'when given a value' do
        subject { tlv.tlv_set_once(ivar_name, expected_value) }
        it_behaves_like 'tlv_set_once'
      end
    end

    describe 'tlv_new' do
      context 'without a default value' do
        subject { tlv.tlv_new(ivar_name) }

        it 'creates a new Conncurrent::ThreadLocalVar object' do
          expect(subject).to be_a(Concurrent::ThreadLocalVar)
        end

        it 'creates a TLV with no value' do
          expect(subject.value).to be_nil
        end

        it 'has a default that is nil' do
          expect(tlv.tlv_default(ivar_name)).to be_nil
        end
      end

      context 'with a default value' do
        subject { tlv.tlv_new(ivar_name, default_value) }
        let(:default_value) { 42 }

        it 'creates a new Conncurrent::ThreadLocalVar object' do
          expect(subject).to be_a(Concurrent::ThreadLocalVar)
        end

        it 'creates a TLV with the default value' do
          expect(subject.value).to eq default_value
        end

        it 'has a local value separate from the default' do
          subject
          tlv.tlv_set(ivar_name, 56)
          expect(tlv.tlv_get(ivar_name)).to eq 56
          expect(tlv.tlv_default(ivar_name)).to eq default_value
        end

        it 'has a default matching the original default value' do
          subject
          expect(tlv.tlv_default(ivar_name)).to eq default_value
        end
      end

      context 'with a default block' do
        subject { tlv.tlv_new(ivar_name, &default_block) }
        let(:default_value) { 99 }
        let(:default_block) { -> { default_value } }

        it 'creates a new Conncurrent::ThreadLocalVar object' do
          expect(subject).to be_a(Concurrent::ThreadLocalVar)
        end

        it 'creates a TLV with the default value' do
          expect(subject.value).to eq default_value
        end

        it 'has a local value separate from the default' do
          subject
          tlv.tlv_set(ivar_name, 56)
          expect(tlv.tlv_get(ivar_name)).to eq 56
        end

        it 'has a default matching the original default value' do
          subject
          expect(tlv.tlv_default(ivar_name)).to eq default_value
        end
      end
    end

    describe "#tlv_default" do
      subject { tlv.tlv_default(ivar_name) }

      context 'with no defined default' do
        it { is_expected.to be_nil}
      end

      context 'with a defined default' do
        before { tlv.tlv_init(ivar_name, 42) }

        it { is_expected.to eq 42 }

        context 'with a distinct value' do
          before { tlv.tlv_set(ivar_name, 99) }
          it { is_expected.to eq 42 }

          it 'keeps the current thread value separate from the default' do
            expect(tlv.tlv_get(ivar_name)).to eq 99
          end
        end
      end
    end

    describe '#tlv_set_default' do
      context 'with default value' do
        subject { tlv.tlv_set_default(ivar_name, default) }
        let(:default) { 44 }

        it 'assigns the default on the existing TLVar' do
          subject
          expect(tlv.tlv_default(ivar_name)).to eq default
        end

        context 'with existing TLVars' do
          before { subject }
          it 'does not create new TLVar instance' do
            expect(tlv).to_not receive(:tlv_init)
            subject
          end
        end

        context 'with new TLVar' do
          before { tlv.instance_variable_set("@#{ivar_name}".to_sym, nil) }

          it 'creates a new TLV' do
            expect(tlv).to receive(:tlv_init)
            subject
          end

          it 'installs the default' do
            subject
            expect(tlv.tlv_default(ivar_name)).to eq 44
          end
        end
      end

      context 'with default block' do
        subject { tlv.tlv_set_default(ivar_name) { default } }
        let(:default) { 44 }

        it 'assigns the default on the existing TLVar' do
          subject
          expect(tlv.tlv_default(ivar_name)).to eq default
        end

        context 'with existing TLVars' do
          before { subject }
          it 'does not create new TLVar instance' do
            expect(tlv).to_not receive(:tlv_init)
            subject
          end
        end

        context 'with new TLVar' do
          before { tlv.instance_variable_set("@#{ivar_name}".to_sym, nil) }

          it 'creates a new TLV' do
            expect(tlv).to receive(:tlv_init)
            subject
          end

          it 'installs the default' do
            subject
            expect(tlv.tlv_default(ivar_name)).to eq 44
          end
        end

        context 'with both a default and a default block' do
          subject { tlv.tlv_set_default(ivar_name, default) { default } }
          it 'raises an error' do
            expect { subject }.to raise_error(ArgumentError)
          end
        end
      end
    end
  end
end
